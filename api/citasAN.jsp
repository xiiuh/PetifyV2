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
    String idTutorStr = request.getParameter("id_tutor");
    if (idTutorStr == null || idTutorStr.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Falta id_tutor\"}");
        return;
    }

    try {
        int idTutor = Integer.parseInt(idTutorStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT c.id_citas, c.fecha, c.hora, c.id_mascota, m.nombre AS nom_mascota, " +
            "       c.id_vete, v.nom_vete, c.id_tutor " +
            "FROM citas c " +
            "JOIN mascota m ON c.id_mascota = m.id_mascota " +
            "JOIN veterinario v ON c.id_vete = v.id_vete " +
            "WHERE c.id_tutor = ? ORDER BY c.fecha DESC, c.hora DESC");
        ps.setInt(1, idTutor);
        ResultSet rs = ps.executeQuery();

        StringBuilder sb = new StringBuilder("{\"success\":true,\"citas\":[");
        boolean first = true;
        while (rs.next()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("{")
              .append("\"id_citas\":").append(rs.getInt("id_citas")).append(",")
              .append("\"fecha\":\"").append(rs.getString("fecha")).append("\",")
              .append("\"hora\":\"").append(rs.getString("hora")).append("\",")
              .append("\"id_mascota\":").append(rs.getInt("id_mascota")).append(",")
              .append("\"nombre_mascota\":\"").append(rs.getString("nom_mascota").replace("\"","\\\"")).append("\",")
              .append("\"id_vete\":").append(rs.getInt("id_vete")).append(",")
              .append("\"nombre_veterinario\":\"").append(rs.getString("nom_vete").replace("\"","\\\"")).append("\",")
              .append("\"id_tutor\":").append(rs.getInt("id_tutor"))
              .append("}");
        }
        sb.append("]}");
        rs.close(); ps.close(); con.close();
        out.print(sb.toString());

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_tutor inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
