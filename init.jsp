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
            "id_vete INT NULL," +
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

        st.executeUpdate("CREATE TABLE IF NOT EXISTS productos (" +
            "id_producto INT NOT NULL AUTO_INCREMENT PRIMARY KEY," +
            "nombre VARCHAR(150) NOT NULL," +
            "descripcion VARCHAR(255) DEFAULT ''," +
            "cantidad INT NOT NULL DEFAULT 0," +
            "precio DOUBLE NOT NULL," +
            "imagen VARCHAR(255) DEFAULT NULL)");
        try {
            st.executeUpdate("ALTER TABLE productos ADD COLUMN imagen VARCHAR(255) DEFAULT NULL");
        } catch (Exception ignored) {}

        st.executeUpdate("CREATE TABLE IF NOT EXISTS ordenes (" +
            "id_orden INT NOT NULL AUTO_INCREMENT PRIMARY KEY," +
            "id_tutor INT NOT NULL," +
            "fecha_compra DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
            "total DOUBLE NOT NULL," +
            "metodo_pago VARCHAR(20) NOT NULL DEFAULT 'efectivo'," +
            "FOREIGN KEY (id_tutor) REFERENCES tutor(id_tutor))");
        try {
            st.executeUpdate("ALTER TABLE ordenes ADD COLUMN metodo_pago VARCHAR(20) NOT NULL DEFAULT 'efectivo'");
        } catch (Exception ignored) {}

        st.executeUpdate("CREATE TABLE IF NOT EXISTS detalle_orden (" +
            "id_detalle INT NOT NULL AUTO_INCREMENT PRIMARY KEY," +
            "id_orden INT NOT NULL," +
            "id_producto INT NOT NULL," +
            "cantidad INT NOT NULL," +
            "precio_unitario DOUBLE NOT NULL," +
            "FOREIGN KEY (id_orden) REFERENCES ordenes(id_orden) ON DELETE CASCADE," +
            "FOREIGN KEY (id_producto) REFERENCES productos(id_producto))");

        st.close();
        con.close();

    } catch (Exception e) {
        out.println("Error al inicializar BD: " + e.getMessage());
        return;
    }

    response.sendRedirect("index.html");
%>