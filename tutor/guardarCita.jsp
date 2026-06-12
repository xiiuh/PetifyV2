<%@ page contentType="text/plain;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    String fecha      = request.getParameter("fecha");
    String hora       = request.getParameter("hora");
    String idTutor    = request.getParameter("id_tutor");
    String idVete     = request.getParameter("id_vete");
    String idMascota  = request.getParameter("id_mascota");

    if (fecha == null || hora == null || idTutor == null || idVete == null || idMascota == null) {
        out.print("ERROR_PARAMS");
        return;
    }

    java.util.Set<String> horasValidas = new java.util.HashSet<>(java.util.Arrays.asList(
        "09:00","10:00","11:00","12:00","13:00","16:00","17:00","18:00"
    ));
    if (!horasValidas.contains(hora)) {
        out.print("ERROR_PARAMS");
        return;
    }
    try {
        java.time.LocalDate fechaDate = java.time.LocalDate.parse(fecha);
        if (fechaDate.isBefore(java.time.LocalDate.now())) {
            out.print("FECHA_PASADA");
            return;
        }
    } catch (Exception eDateEx) {
        out.print("ERROR_PARAMS");
        return;
    }

    try {
        Context ctx = new javax.naming.InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT COUNT(*) FROM citas WHERE fecha = ? AND hora = ? AND id_vete = ?"
        );
        ps.setString(1, fecha);
        ps.setString(2, hora);
        ps.setInt(3, Integer.parseInt(idVete));
        ResultSet rs = ps.executeQuery();
        rs.next();
        if (rs.getInt(1) > 0) {
            rs.close(); ps.close(); con.close();
            out.print("DUPLICADO");
            return;
        }
        rs.close(); ps.close();

        ps = con.prepareStatement(
            "INSERT INTO citas (fecha, hora, id_tutor, id_vete, id_mascota) VALUES (?, ?, ?, ?, ?)"
        );
        ps.setString(1, fecha);
        ps.setString(2, hora);
        ps.setInt(3, Integer.parseInt(idTutor));
        ps.setInt(4, Integer.parseInt(idVete));
        ps.setInt(5, Integer.parseInt(idMascota));
        ps.executeUpdate();
        ps.close(); con.close();

        out.print("OK");

    } catch (Exception e) {
        System.err.println("[guardarCita] " + e);
        out.print("SQL_ERROR");
    }
%>