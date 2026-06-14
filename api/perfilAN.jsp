<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

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

        if ("POST".equals(request.getMethod())) {
            String nombre   = request.getParameter("nom_tutor");
            String telefono = request.getParameter("telefono");
            String correo   = request.getParameter("correo");

            if (nombre == null || telefono == null || correo == null) {
                con.close();
                out.print("{\"success\":false,\"mensaje\":\"Faltan parámetros para actualizar\"}");
                return;
            }

            PreparedStatement ps = con.prepareStatement(
                "UPDATE tutor SET nom_tutor=?, telefono=?, correo=? WHERE id_tutor=?");
            ps.setString(1, nombre);
            ps.setString(2, telefono);
            ps.setString(3, correo);
            ps.setInt(4, idTutor);
            ps.executeUpdate();
            ps.close(); con.close();
            out.print("{\"success\":true,\"mensaje\":\"Perfil actualizado correctamente\"}");

        } else {
            PreparedStatement ps = con.prepareStatement(
                "SELECT id_tutor, nom_tutor, telefono, correo FROM tutor WHERE id_tutor=?");
            ps.setInt(1, idTutor);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                rs.close(); ps.close(); con.close();
                out.print("{\"success\":false,\"mensaje\":\"Tutor no encontrado\"}");
                return;
            }

            String nombre   = rs.getString("nom_tutor");
            String telefono = rs.getString("telefono");
            String correo   = rs.getString("correo");
            rs.close(); ps.close(); con.close();

            out.print("{\"success\":true,\"tutor\":{"
                + "\"id_tutor\":"    + idTutor + ","
                + "\"nom_tutor\":\"" + (nombre   != null ? nombre.replace("\"","\\\"")   : "") + "\","
                + "\"telefono\":\""  + (telefono != null ? telefono.replace("\"","\\\"") : "") + "\","
                + "\"correo\":\""    + (correo   != null ? correo.replace("\"","\\\"")   : "") + "\""
                + "}}");
        }

    } catch (NumberFormatException e) {
        out.print("{\"success\":false,\"mensaje\":\"id_tutor inválido\"}");
    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
