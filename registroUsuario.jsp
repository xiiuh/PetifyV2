<%@ page import="java.sql.*, java.security.MessageDigest" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%! 
    public String hashPassword(String pass) {
    try {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hashed = md.digest(pass.getBytes("UTF-8"));
        StringBuilder sb = new StringBuilder();
        for (byte b : hashed) sb.append(String.format("%02x", b));
        return sb.toString();
    } catch (Exception e) {
        return pass;
    }
}
%>

<%
    request.setCharacterEncoding("UTF-8");

    String nombre = request.getParameter("nombre");
    String email  = request.getParameter("correo");
    String contra = request.getParameter("password");
    String telf   = request.getParameter("telefono");

    if (nombre == null || email == null || contra == null || telf == null) {
        response.setStatus(400);
        out.print("invalid_params");
        return;
    }

    nombre = nombre.trim();
    email  = email.trim();
    telf   = telf.trim();

    if (nombre.length() < 2 || email.isEmpty() || contra.length() < 6 || !telf.matches("^\\d{10}$")) {
        response.setStatus(400);
        out.print("invalid_params");
        return;
    }
    if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
        response.setStatus(400);
        out.print("invalid_params");
        return;
    }

    String passHash = hashPassword(contra);

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/petify?useSSL=false&allowPublicKeyRetrieval=true",
            "root", "n0m3l0"
        );

        String checkSql = "SELECT id_tutor FROM tutor WHERE correo = ?";
        PreparedStatement check = con.prepareStatement(checkSql);
        check.setString(1, email);
        ResultSet rs = check.executeQuery();

        if (rs.next()) {
            rs.close(); check.close(); con.close();
            response.setStatus(409);
            out.print("email_exists");
            return;
        }
        rs.close();
        check.close();

        String sqlTutor = "INSERT INTO tutor (nom_tutor, telefono, correo, contrasena) VALUES (?, ?, ?, ?)";
        PreparedStatement stTutor = con.prepareStatement(sqlTutor);
        stTutor.setString(1, nombre);
        stTutor.setString(2, telf);
        stTutor.setString(3, email);
        stTutor.setString(4, passHash);
        stTutor.executeUpdate();
        stTutor.close();

        String sqlUsuario = "INSERT INTO usuarios (correo, contrasena, rol) VALUES (?, ?, 'tutor')";
        PreparedStatement stUsuario = con.prepareStatement(sqlUsuario);
        stUsuario.setString(1, email);
        stUsuario.setString(2, passHash);
        stUsuario.executeUpdate();
        stUsuario.close();

        String sqlRol = "INSERT INTO roles (correo, rol) VALUES (?, 'tutor')";
        PreparedStatement stRol = con.prepareStatement(sqlRol);
        stRol.setString(1, email);
        stRol.executeUpdate();
        stRol.close();

        con.close();
        response.setStatus(200);
        out.print("ok");

    } catch (Exception e) {
        response.setStatus(500);
        out.print("server_error");
    }
%>