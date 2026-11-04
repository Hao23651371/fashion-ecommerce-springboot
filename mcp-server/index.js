import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createMcpServer } from "./mcp-app.js";

// =========================================================================
// CHẾ ĐỘ 1: STDIO TRANSPORT (DÀNH CHO CLAUDE DESKTOP / MÁY CÁ NHÂN)
// =========================================================================
// Khởi động McpServer với transport Stdio
// Lưu ý: Chỉ dùng console.error để ghi log, TUYỆT ĐỐI KHÔNG DÙNG console.log!
// =========================================================================
async function main() {
  const server = createMcpServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("FashionShop Admin MCP Server đã khởi động thành công trên stdio!");
}

main().catch((error) => {
  console.error("Lỗi nghiêm trọng khi khởi động MCP Server (stdio):", error);
  process.exit(1);
});
