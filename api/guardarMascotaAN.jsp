<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    String nombre    = request.getParameter("nombre");
    String especie   = request.getParameter("especie");
    String raza      = request.getParameter("raza");
    String edad      = request.getParameter("edad");
    String pesoStr   = request.getParameter("peso");
    String sexo      = request.getParameter("sexo");
    String idTutorStr  = request.getParameter("id_tutor");
    String idMascotaStr = request.getParameter("id_mascota");

    if (nombre == null || especie == null || raza == null || edad == null ||
        pesoStr == null || sexo == null || idTutorStr == null) {
        out.print("{\"success\":false,\"mensaje\":\"Faltan parámetros obligatorios\"}");
        return;
    }

    try {
        double peso    = Double.parseDouble(pesoStr);
        int    idTutor = Integer.parseInt(idTutorStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        if (idMascotaStr != null && !idMascotaStr.isEmpty()) {
            int idMascota = Integer.parseInt(idMascotaStr);
            PreparedStatement ps = con.prepareStatement(
                "UPDATE mascota SET nombre=?, especie=?, raza=?, edad=?, peso=?, sexo=? " +
                "WHERE id_mascota=? AND id_tutor=?");
            ps.setString(1, nombre); ps.setString(2, especie);
            ps.setString(3, raza);   ps.setString(4, edad);
            ps.setDouble(5, peso);   ps.setString(6, sexo);
            ps.setInt(7, idMascota); ps.setInt(8, idTutor);
            ps.executeUpdate();
            ps.close();
        } else {
            PreparedStatement ps = con.prepareStatement(
                "INSERT INTO mascota (nombre, especie, raza, edad, peso, sexo, id_tutor) " +
                "VALUES (?,?,?,?,?,?,?)");
            ps.setString(1, nombre); ps.setString(2, especie);
            ps.setString(3, raza);   ps.setString(4, edad);
            ps.setDouble(5, peso);   ps.setString(6, sexo);
            ps.setInt(7, idTutor);
            ps.executeUpdate();
            ps.close();
        }
        con.close();
        out.print("{\"success\":true,\"mensaje\":\"Mascota guardada correctamente\"}");

    } catch (Exception e) {
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
