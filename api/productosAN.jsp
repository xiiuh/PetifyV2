<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    try {
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT id_producto, nombre, descripcion, precio, cantidad, imagen " +
            "FROM productos WHERE cantidad > 0 ORDER BY nombre");
        ResultSet rs = ps.executeQuery();

        StringBuilder sb = new StringBuilder("{\"success\":true,\"productos\":[");
        boolean first = true;
        while (rs.next()) {
            if (!first) sb.append(",");
            first = false;
            String desc  = rs.getString("descripcion");
            String imagen = rs.getString("imagen");
            sb.append("{")
              .append("\"id_producto\":").append(rs.getInt("id_producto")).append(",")
              .append("\"nombre\":\"").append(rs.getString("nombre").replace("\"","\\\"")).append("\",")
              .append("\"descripcion\":\"").append(desc  != null ? desc.replace("\"","\\\"")  : "").append("\",")
              .append("\"precio\":").append(rs.getDouble("precio")).append(",")
              .append("\"cantidad\":").append(rs.getInt("cantidad")).append(",")
              .append("\"imagen\":\"").append(imagen != null ? imagen.replace("\"","\\\"") : "").append("\"")
              .append("}");
        }
        sb.append("]}");
        rs.close(); ps.close(); con.close();
        out.print(sb.toString());

    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
