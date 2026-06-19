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
    String idMascotaStr = request.getParameter("id_mascota");
    if (idMascotaStr == null || idMascotaStr.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Falta id_mascota\"}");
        return;
    }

    try {
        int idMascota = Integer.parseInt(idMascotaStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        // 0. Verificar que la mascota pertenece al tutor autenticado
        PreparedStatement psOwn = con.prepareStatement(
            "SELECT id_mascota FROM mascota WHERE id_mascota = ? AND id_tutor = ?");
        psOwn.setInt(1, idMascota);
        psOwn.setInt(2, idTutorAuth);
        ResultSet rsOwn = psOwn.executeQuery();
        boolean esPropia = rsOwn.next();
        rsOwn.close(); psOwn.close();
        if (!esPropia) {
            con.close();
            out.print("{\"success\":false,\"mensaje\":\"No autorizado\"}");
            return;
        }

        // 1. Nullear FK en consultas que apuntan a citas de esta mascota
        PreparedStatement ps = con.prepareStatement(
            "UPDATE consultas SET id_cita = NULL WHERE id_cita IN " +
            "(SELECT id_citas FROM citas WHERE id_mascota = ?)");
        ps.setInt(1, idMascota);
        ps.executeUpdate(); ps.close();

        // 2. Eliminar citas de la mascota
        ps = con.prepareStatement("DELETE FROM citas WHERE id_mascota = ?");
        ps.setInt(1, idMascota);
        ps.executeUpdate(); ps.close();

        // 3. Eliminar la mascota
        ps = con.prepareStatement("DELETE FROM mascota WHERE id_mascota = ? AND id_tutor = ?");
        ps.setInt(1, idMascota);
        ps.setInt(2, idTutorAuth);
        ps.executeUpdate(); ps.close();

        con.close();
        out.print("{\"success\":true,\"mensaje\":\"Mascota eliminada\"}");

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_mascota inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
