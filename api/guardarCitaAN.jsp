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
    String fecha       = request.getParameter("fecha");
    String hora        = request.getParameter("hora");
    String idMascotaStr = request.getParameter("id_mascota");
    String idVeteStr    = request.getParameter("id_vete");
    String idCitasStr   = request.getParameter("id_citas");

    if (fecha == null || hora == null || idMascotaStr == null || idVeteStr == null) {
        out.print("{\"success\":false,\"mensaje\":\"Faltan parámetros obligatorios\"}");
        return;
    }

    java.util.Set<String> horasOk = new java.util.HashSet<>(java.util.Arrays.asList(
        "09:00","10:00","11:00","12:00","13:00","16:00","17:00","18:00"
    ));
    if (!horasOk.contains(hora)) {
        out.print("{\"success\":false,\"mensaje\":\"Hora no válida\"}");
        return;
    }

    try {
        // Validar fecha no pasada
        java.time.LocalDate fechaDate = java.time.LocalDate.parse(fecha);
        if (fechaDate.isBefore(java.time.LocalDate.now())) {
            out.print("{\"success\":false,\"mensaje\":\"No puedes agendar en una fecha pasada\"}");
            return;
        }

        int idMascota = Integer.parseInt(idMascotaStr);
        int idVete    = Integer.parseInt(idVeteStr);
        int idTutor   = idTutorAuth;

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        if (idCitasStr != null && !idCitasStr.isEmpty()) {
            // Edición
            int idCitas = Integer.parseInt(idCitasStr);

            // Verificar duplicado excluyendo la cita actual
            PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM citas WHERE fecha=? AND hora=? AND id_vete=? AND id_citas<>?");
            ps.setString(1, fecha); ps.setString(2, hora);
            ps.setInt(3, idVete);   ps.setInt(4, idCitas);
            ResultSet rs = ps.executeQuery(); rs.next();
            if (rs.getInt(1) > 0) {
                rs.close(); ps.close(); con.close();
                out.print("{\"success\":false,\"mensaje\":\"Ese horario ya está ocupado\"}");
                return;
            }
            rs.close(); ps.close();

            ps = con.prepareStatement(
                "UPDATE citas SET fecha=?, hora=?, id_mascota=?, id_vete=? WHERE id_citas=? AND id_tutor=?");
            ps.setString(1, fecha); ps.setString(2, hora);
            ps.setInt(3, idMascota); ps.setInt(4, idVete);
            ps.setInt(5, idCitas);   ps.setInt(6, idTutor);
            ps.executeUpdate(); ps.close();
        } else {
            // Nuevo registro
            PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM citas WHERE fecha=? AND hora=? AND id_vete=?");
            ps.setString(1, fecha); ps.setString(2, hora); ps.setInt(3, idVete);
            ResultSet rs = ps.executeQuery(); rs.next();
            if (rs.getInt(1) > 0) {
                rs.close(); ps.close(); con.close();
                out.print("{\"success\":false,\"mensaje\":\"Ese horario ya está ocupado\"}");
                return;
            }
            rs.close(); ps.close();

            ps = con.prepareStatement(
                "INSERT INTO citas (fecha, hora, id_mascota, id_vete, id_tutor) VALUES (?,?,?,?,?)");
            ps.setString(1, fecha); ps.setString(2, hora);
            ps.setInt(3, idMascota); ps.setInt(4, idVete); ps.setInt(5, idTutor);
            ps.executeUpdate(); ps.close();
        }

        con.close();
        out.print("{\"success\":true,\"mensaje\":\"Cita guardada correctamente\"}");

    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
