const net = require("net");
const tls = require("tls");

function toBase64(value) {
  return Buffer.from(value, "utf8").toString("base64");
}

function normalizeNewlines(value) {
  return value.replace(/\r?\n/g, "\r\n");
}

function sanitizeSmtpData(value) {
  return normalizeNewlines(value).replace(/^\./gm, "..");
}

function createResponseReader(socket) {
  let buffer = "";
  const queue = [];
  let resolver = null;

  socket.on("data", (chunk) => {
    buffer += chunk.toString("utf8");
    const parts = buffer.split("\r\n");
    buffer = parts.pop() || "";
    for (const line of parts) {
      if (!line) continue;
      queue.push(line);
    }
    if (resolver) {
      const fn = resolver;
      resolver = null;
      fn();
    }
  });

  async function nextLine(timeoutMs = 15000) {
    if (queue.length > 0) return queue.shift();
    return await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error("SMTP timeout while waiting for server response"));
      }, timeoutMs);
      resolver = () => {
        clearTimeout(timeout);
        resolve(queue.shift());
      };
    });
  }

  async function readResponse(expected) {
    const lines = [];
    while (true) {
      const line = await nextLine();
      lines.push(line);
      const match = line.match(/^(\d{3})([ -])(.*)$/);
      if (!match) continue;
      if (match[2] === " ") {
        const code = Number(match[1]);
        if (expected && !expected.includes(code)) {
          throw new Error(`SMTP unexpected response ${code}: ${lines.join(" | ")}`);
        }
        return { code, lines };
      }
    }
  }

  return { readResponse };
}

async function writeLine(socket, line) {
  await new Promise((resolve, reject) => {
    socket.write(`${line}\r\n`, (err) => (err ? reject(err) : resolve()));
  });
}

function getMailConfig() {
  const host = (process.env.BREVO_HOST || "smtp-relay.brevo.com").trim();
  const port = Number((process.env.BREVO_PORT || "587").trim());
  const user = (process.env.BREVO_USER || "").trim();
  const pass = (process.env.BREVO_PASS || "").trim();
  const sender = (process.env.EMAIL_SENDER_EMAIL || "no-reply@example.com").trim();
  const senderName = (process.env.EMAIL_SENDER_NAME || "Daily Check").trim();

  if (!host || !port || !user || !pass) {
    throw new Error("Missing Brevo SMTP environment variables");
  }
  return { host, port, user, pass, sender, senderName };
}

async function sendSmtpMail(input) {
  const { host, port, user, pass, sender, senderName } = getMailConfig();

  const plainSocket = net.createConnection({ host, port });
  plainSocket.setTimeout(20000);

  await new Promise((resolve, reject) => {
    plainSocket.once("connect", () => resolve());
    plainSocket.once("error", (err) => reject(err));
  });

  const plainReader = createResponseReader(plainSocket);
  await plainReader.readResponse([220]);
  await writeLine(plainSocket, "EHLO dailycheck.com");
  await plainReader.readResponse([250]);
  await writeLine(plainSocket, "STARTTLS");
  await plainReader.readResponse([220]);

  const secureSocket = tls.connect({
    socket: plainSocket,
    servername: host,
    rejectUnauthorized: true
  });

  await new Promise((resolve, reject) => {
    secureSocket.once("secureConnect", () => resolve());
    secureSocket.once("error", (err) => reject(err));
  });

  const reader = createResponseReader(secureSocket);
  await writeLine(secureSocket, "EHLO dailycheck.com");
  await reader.readResponse([250]);
  await writeLine(secureSocket, "AUTH LOGIN");
  await reader.readResponse([334]);
  await writeLine(secureSocket, toBase64(user));
  await reader.readResponse([334]);
  await writeLine(secureSocket, toBase64(pass));
  await reader.readResponse([235]);
  await writeLine(secureSocket, `MAIL FROM:<${sender}>`);
  await reader.readResponse([250]);
  await writeLine(secureSocket, `RCPT TO:<${input.to}>`);
  await reader.readResponse([250, 251]);
  await writeLine(secureSocket, "DATA");
  await reader.readResponse([354]);

  const mailData = [
    `From: ${senderName} <${sender}>`,
    `To: ${input.to}`,
    `Subject: ${input.subject}`,
    "MIME-Version: 1.0",
    "Content-Type: text/html; charset=UTF-8",
    "",
    sanitizeSmtpData(input.html),
    "."
  ].join("\r\n");

  await new Promise((resolve, reject) => {
    secureSocket.write(`${mailData}\r\n`, (err) => (err ? reject(err) : resolve()));
  });
  await reader.readResponse([250]);
  await writeLine(secureSocket, "QUIT");

  secureSocket.end();
}

module.exports = { sendSmtpMail };
