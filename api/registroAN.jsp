<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    String nomTutor  = request.getParameter("nom_tutor");
    String correo    = request.getParameter("correo");
    String contra    = request.getParameter("contrasena");
    String telefono  = request.getParameter("telefono");
    if (telefono == null) telefono = "";

    if (nomTutor == null || nomTutor.trim().isEmpty() ||
        correo   == null || correo.trim().isEmpty()   ||
        contra   == null || contra.trim().isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"Completa los campos obligatorios\"}");
        return;
    }

    Connection con = null;
    try {
        // Hash SHA-256 igual que el resto de la API
        java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest(contra.getBytes("UTF-8"));
        StringBuilder hex = new StringBuilder();
        for (byte b : h) hex.append(String.format("%02x", b));
        String hashPass = hex.toString();

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        con = ds.getConnection();
        con.setAutoCommit(false);

        // Verificar correo duplicado
        PreparedStatement ps = con.prepareStatement(
            "SELECT COUNT(*) FROM usuarios WHERE correo = ?");
        ps.setString(1, correo);
        ResultSet rs = ps.executeQuery();
        rs.next();
        if (rs.getInt(1) > 0) {
            rs.close(); ps.close(); con.rollback(); con.close();
            out.print("{\"success\":false,\"mensaje\":\"El correo ya está registrado\"}");
            return;
        }
        rs.close(); ps.close();

        // Insertar en usuarios
        ps = con.prepareStatement(
            "INSERT INTO usuarios (correo, contrasena, rol) VALUES (?, ?, 'tutor')");
        ps.setString(1, correo);
        ps.setString(2, hashPass);
        ps.executeUpdate(); ps.close();

        // Insertar en tutor
        ps = con.prepareStatement(
            "INSERT INTO tutor (nom_tutor, telefono, correo, contrasena) VALUES (?, ?, ?, ?)");
        ps.setString(1, nomTutor.trim());
        ps.setString(2, telefono.trim());
        ps.setString(3, correo);
        ps.setString(4, hashPass);
        ps.executeUpdate(); ps.close();

        // Insertar en roles para acceso web
        ps = con.prepareStatement(
            "INSERT INTO roles (correo, rol) VALUES (?, 'tutor')");
        ps.setString(1, correo);
        ps.executeUpdate(); ps.close();

        con.commit(); con.close();
        out.print("{\"success\":true,\"mensaje\":\"Registro exitoso\"}");

    } catch (Exception e) {
        try { if (con != null) { con.rollback(); con.close(); } } catch (Exception ignored) {}
        out.print("{\"success\":false,\"mensaje\":\"Error al registrar\"}");
    }
%>
