<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    String correo = request.getParameter("correo");
    String contra = request.getParameter("contrasena");

    if (correo == null || contra == null || correo.isEmpty() || contra.isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Faltan parámetros\"}");
        return;
    }

    try {
        // Hash SHA-256 igual que el Realm (sin salt, 1 iteración)
        java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest(contra.getBytes("UTF-8"));
        StringBuilder hex = new StringBuilder();
        for (byte b : h) hex.append(String.format("%02x", b));
        String hashPass = hex.toString();

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT u.correo, u.rol FROM usuarios u WHERE u.correo=? AND u.contrasena=?");
        ps.setString(1, correo);
        ps.setString(2, hashPass);
        ResultSet rs = ps.executeQuery();

        if (!rs.next()) {
            rs.close(); ps.close(); con.close();
            out.print("{\"success\":false,\"mensaje\":\"Credenciales incorrectas\"}");
            return;
        }
        String rol = rs.getString("rol");
        rs.close(); ps.close();

        ps = con.prepareStatement(
            "SELECT id_tutor, nom_tutor, telefono FROM tutor WHERE correo=?");
        ps.setString(1, correo);
        rs = ps.executeQuery();

        if (!rs.next()) {
            rs.close(); ps.close(); con.close();
            out.print("{\"success\":false,\"mensaje\":\"Tutor no encontrado\"}");
            return;
        }
        int    idTutor  = rs.getInt("id_tutor");
        String nombre   = rs.getString("nom_tutor");
        String telefono = rs.getString("telefono");
        rs.close(); ps.close(); con.close();

        out.print("{\"success\":true"
            + ",\"id_tutor\":"  + idTutor
            + ",\"nombre\":\""  + nombre.replace("\"","\\\"") + "\""
            + ",\"correo\":\""  + correo.replace("\"","\\\"") + "\""
            + ",\"telefono\":\"" + telefono.replace("\"","\\\"") + "\""
            + ",\"rol\":\""     + rol.replace("\"","\\\"") + "\""
            + "}");

    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno: " + e.getMessage().replace("\"","'") + "\"}");
    }
%>
