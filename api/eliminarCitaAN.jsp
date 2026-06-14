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
    String idCitasStr = request.getParameter("id_citas");
    if (idCitasStr == null || idCitasStr.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Falta id_citas\"}");
        return;
    }

    try {
        int idCitas = Integer.parseInt(idCitasStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        // 1. Nullear FK en consultas para preservar el expediente
        PreparedStatement ps = con.prepareStatement(
            "UPDATE consultas SET id_cita = NULL WHERE id_cita = ?");
        ps.setInt(1, idCitas);
        ps.executeUpdate(); ps.close();

        // 2. Eliminar la cita
        ps = con.prepareStatement("DELETE FROM citas WHERE id_citas = ?");
        ps.setInt(1, idCitas);
        ps.executeUpdate(); ps.close();

        con.close();
        out.print("{\"success\":true,\"mensaje\":\"Cita eliminada\"}");

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_citas inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
