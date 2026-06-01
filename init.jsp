<%@ page import="java.sql.*" contentType="text/html;charset=UTF-8" %>
<%
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/?useSSL=false&allowPublicKeyRetrieval=true",
            "root", "n0m3l0"
        );
        Statement st = con.createStatement();

        st.executeUpdate("CREATE DATABASE IF NOT EXISTS petify");
        st.executeUpdate("USE petify");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS usuarios (" +
            "id_usuario INT PRIMARY KEY AUTO_INCREMENT," +
            "correo VARCHAR(100) NOT NULL UNIQUE," +
            "contrasena VARCHAR(64) NOT NULL," +
            "rol VARCHAR(20) NOT NULL)");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS roles (" +
            "correo VARCHAR(100) NOT NULL," +
            "rol VARCHAR(20) NOT NULL," +
            "FOREIGN KEY (correo) REFERENCES usuarios(correo))");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS veterinario (" +
            "id_vete INT NOT NULL PRIMARY KEY AUTO_INCREMENT," +
            "nom_vete VARCHAR(50) NOT NULL," +
            "especialidad VARCHAR(50) NOT NULL," +
            "telefono VARCHAR(15) NOT NULL," +
            "correo VARCHAR(50) NOT NULL," +
            "contrasena VARCHAR(255) NOT NULL)");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS tutor (" +
            "id_tutor INT NOT NULL PRIMARY KEY AUTO_INCREMENT," +
            "nom_tutor VARCHAR(50) NOT NULL," +
            "telefono VARCHAR(15) NOT NULL," +
            "correo VARCHAR(50)," +
            "contrasena VARCHAR(255) NOT NULL)");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS mascota (" +
            "id_mascota INT NOT NULL PRIMARY KEY AUTO_INCREMENT," +
            "nombre VARCHAR(50) NOT NULL," +
            "edad VARCHAR(50) NOT NULL," +
            "especie VARCHAR(50) NOT NULL," +
            "sexo VARCHAR(50) NOT NULL," +
            "raza VARCHAR(50) NOT NULL," +
            "peso DECIMAL(5,2) NOT NULL," +
            "id_vete INT NOT NULL," +
            "id_tutor INT NOT NULL," +
            "FOREIGN KEY (id_vete) REFERENCES veterinario(id_vete)," +
            "FOREIGN KEY (id_tutor) REFERENCES tutor(id_tutor))");

        st.executeUpdate("CREATE TABLE IF NOT EXISTS citas (" +
            "id_citas INT NOT NULL PRIMARY KEY AUTO_INCREMENT," +
            "fecha DATE NOT NULL," +
            "hora TIME NOT NULL," +
            "id_mascota INT NOT NULL," +
            "id_vete INT NOT NULL," +
            "id_tutor INT NOT NULL," +
            "FOREIGN KEY (id_mascota) REFERENCES mascota(id_mascota)," +
            "FOREIGN KEY (id_vete) REFERENCES veterinario(id_vete)," +
            "FOREIGN KEY (id_tutor) REFERENCES tutor(id_tutor)," +
            "UNIQUE (fecha, hora, id_vete))");

        st.close();
        con.close();

    } catch (Exception e) {
        out.println("Error al inicializar BD: " + e.getMessage());
        return;
    }

    response.sendRedirect("index.html");
%>