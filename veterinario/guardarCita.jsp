<%@ page contentType="text/plain;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>

<%
    if(request.getUserPrincipal()==null){
        out.print("ERROR_AUTH");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    String fecha = request.getParameter("fecha");
    String hora = request.getParameter("hora");
    String idTutor = request.getParameter("id_tutor");
    String idMascota = request.getParameter("id_mascota");
    String idVeteReq = request.getParameter("id_vete");

    if(
        fecha==null ||
        hora==null ||
        idTutor==null ||
        idMascota==null ||
        idVeteReq==null
    ){
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

    try{

        Context ctx = new InitialContext();

        DataSource ds =
            (DataSource) ctx.lookup("java:comp/env/jdbc/petify");

        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement(
            "SELECT id_vete " +
            "FROM veterinario " +
            "WHERE correo=?"
        );

        ps.setString(1, correo);

        ResultSet rs = ps.executeQuery();

        if(!rs.next()){

            rs.close();
            ps.close();
            con.close();

            out.print("ERROR_AUTH");
            return;
        }

        int idVeteReal = rs.getInt("id_vete");

        rs.close();
        ps.close();

        if(idVeteReal != Integer.parseInt(idVeteReq)){

            con.close();

            out.print("ERROR_AUTH");
            return;
        }

        ps = con.prepareStatement(
            "SELECT COUNT(*) " +
            "FROM citas " +
            "WHERE fecha=? " +
            "AND hora=? " +
            "AND id_vete=?"
        );

        ps.setString(1, fecha);
        ps.setString(2, hora);
        ps.setInt(3, idVeteReal);

        rs = ps.executeQuery();

        rs.next();

        boolean ocupado = rs.getInt(1) > 0;

        rs.close();
        ps.close();

        if(ocupado){

            con.close();

            out.print("DUPLICADO");
            return;
        }

        ps = con.prepareStatement(
            "INSERT INTO citas " +
            "(fecha,hora,id_mascota,id_vete,id_tutor) " +
            "VALUES(?,?,?,?,?)"
        );

        ps.setString(1, fecha);
        ps.setString(2, hora);
        ps.setInt(3, Integer.parseInt(idMascota));
        ps.setInt(4, idVeteReal);
        ps.setInt(5, Integer.parseInt(idTutor));

        ps.executeUpdate();

        ps.close();
        con.close();

        out.print("OK");

    }
    catch(Exception e){

        out.print("SQL_ERROR");

    }
%>