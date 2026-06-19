<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }
%>
<%@ include file="_checkToken.jsp" %>
<%
    try {
        int idTutor = idTutorAuth;

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT id_mascota, nombre, especie, raza, edad, peso, sexo, id_tutor " +
            "FROM mascota WHERE id_tutor=? ORDER BY nombre");
        ps.setInt(1, idTutor);
        ResultSet rs = ps.executeQuery();

        StringBuilder sb = new StringBuilder("{\"success\":true,\"mascotas\":[");
        boolean first = true;
        while (rs.next()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("{")
              .append("\"id_mascota\":").append(rs.getInt("id_mascota")).append(",")
              .append("\"nombre\":\"").append(rs.getString("nombre").replace("\"","\\\"")).append("\",")
              .append("\"especie\":\"").append(rs.getString("especie").replace("\"","\\\"")).append("\",")
              .append("\"raza\":\"").append(rs.getString("raza").replace("\"","\\\"")).append("\",")
              .append("\"edad\":\"").append(rs.getString("edad").replace("\"","\\\"")).append("\",")
              .append("\"peso\":").append(rs.getDouble("peso")).append(",")
              .append("\"sexo\":\"").append(rs.getString("sexo").replace("\"","\\\"")).append("\",")
              .append("\"id_tutor\":").append(rs.getInt("id_tutor"))
              .append("}");
        }
        sb.append("]}");
        rs.close(); ps.close(); con.close();
        out.print(sb.toString());

    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
