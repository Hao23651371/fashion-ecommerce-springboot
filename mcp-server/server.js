import http from "http";
import { URL } from "url";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { createMcpServer, pool } from "./mcp-app.js";

// =========================================================================
// CHẾ ĐỘ 2: SSE / HTTP TRANSPORT (DÀNH CHO DEPLOY CLOUD / DOCKER / MẠNG LAN)
// =========================================================================
// Chạy server độc lập lắng nghe cổng HTTP (mặc định 3000 hoặc process.env.PORT)
// Cung cấp 2 endpoint chuẩn của giao thức MCP:
//   - GET  /sse      : Thiết lập kênh truyền luồng Server-Sent Events
//   - POST /messages : Nhận câu lệnh JSON-RPC từ AI Client (kèm query ?sessionId=...)
//   - GET  /health   : Kiểm tra trạng thái hoạt động của server (Health check)
// =========================================================================

const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || "0.0.0.0";

// Bảng lưu trữ các phiên kết nối SSE đang hoạt động
const activeSessions = new Map();

// Cấu hình CORS để cho phép các ứng dụng Web / AI Client kết nối
function setCorsHeaders(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

const httpServer = http.createServer(async (req, res) => {
  setCorsHeaders(res);

  // Xử lý Preflight request của trình duyệt (CORS)
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  const reqUrl = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  const pathname = reqUrl.pathname;

  // -----------------------------------------------------------------------
  // 1. Health check & Trang chủ: GET / hoặc GET /health
  // -----------------------------------------------------------------------
  if (req.method === "GET" && (pathname === "/" || pathname === "/health")) {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(
      JSON.stringify(
        {
          status: "UP",
          service: "FashionShop Admin AI Copilot (MCP SSE Server)",
          version: "1.0.0",
          transport: "SSE / HTTP",
          active_sessions: activeSessions.size,
          endpoints: {
            sse: "/sse",
            messages: "/messages?sessionId=<SESSION_ID>"
          },
          tools_count: 5,
          timestamp: new Date().toISOString()
        },
        null,
        2
      )
    );
    return;
  }

  // -----------------------------------------------------------------------
  // 2. Endpoint thiết lập luồng SSE: GET /sse
  // -----------------------------------------------------------------------
  if (req.method === "GET" && pathname === "/sse") {
    console.log(`[SSE] Nhận yêu cầu kết nối mới từ: ${req.socket.remoteAddress}`);

    const transport = new SSEServerTransport("/messages", res);
    const mcpServer = createMcpServer();

    activeSessions.set(transport.sessionId, { transport, mcpServer });

    transport.onclose = async () => {
      console.log(`[SSE] Phiên kết nối đã đóng: ${transport.sessionId}`);
      activeSessions.delete(transport.sessionId);
      try {
        await mcpServer.close();
      } catch (err) {
        console.error("Lỗi khi đóng MCP Server instance:", err);
      }
    };

    try {
      await mcpServer.connect(transport);
      console.log(`[SSE] Kết nối thành công cho phiên: ${transport.sessionId}`);
    } catch (error) {
      console.error("[SSE] Lỗi khi kết nối MCP Server:", error);
      if (!res.headersSent) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end(`Lỗi kết nối SSE: ${error.message}`);
      }
    }
    return;
  }

  // -----------------------------------------------------------------------
  // 3. Endpoint nhận lệnh JSON-RPC: POST /messages
  // -----------------------------------------------------------------------
  if (req.method === "POST" && pathname === "/messages") {
    const sessionId = reqUrl.searchParams.get("sessionId");

    if (!sessionId || !activeSessions.has(sessionId)) {
      res.writeHead(400, { "Content-Type": "application/json; charset=utf-8" });
      res.end(
        JSON.stringify({
          error: "Không tìm thấy sessionId hoặc phiên kết nối SSE đã hết hạn."
        })
      );
      return;
    }

    const session = activeSessions.get(sessionId);
    try {
      await session.transport.handlePostMessage(req, res);
    } catch (error) {
      console.error(`[POST /messages] Lỗi xử lý tin nhắn cho session ${sessionId}:`, error);
      if (!res.headersSent) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end(`Lỗi xử lý tin nhắn: ${error.message}`);
      }
    }
    return;
  }

  // 404 Not Found cho các route khác
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("404 Not Found - FashionShop MCP Server");
});

// Khởi động lắng nghe cổng mạng
httpServer.listen(PORT, HOST, () => {
  console.log("==================================================================");
  console.log(`🚀 FashionShop MCP SSE Server đang chạy tại: http://${HOST}:${PORT}`);
  console.log(`👉 Endpoint SSE     : http://${HOST}:${PORT}/sse`);
  console.log(`👉 Health check URL : http://${HOST}:${PORT}/health`);
  console.log("==================================================================");
});

// Xử lý dừng server an toàn (Graceful Shutdown)
async function shutdown() {
  console.log("\nĐang tắt MCP SSE Server an toàn...");
  httpServer.close(async () => {
    try {
      await pool.end();
      console.log("Đã ngắt kết nối database pool MariaDB.");
    } catch (err) {
      console.error("Lỗi khi đóng database pool:", err);
    }
    process.exit(0);
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
