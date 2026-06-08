<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>

<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    String idParam = request.getParameter("id");

    if (idParam == null) {
        response.sendRedirect("listarCitas.jsp");
        return;
    }

    int idCita = Integer.parseInt(idParam);

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

    int idVete = 0;

    if(rs.next()){
        idVete = rs.getInt("id_vete");
    }

    rs.close();
    ps.close();

    int idTutorActual = 0;
    int idMascotaActual = 0;

    String fechaActual = "";
    String horaActual = "";

    ps = con.prepareStatement(
        "SELECT * " +
        "FROM citas " +
        "WHERE id_citas=? " +
        "AND id_vete=?"
    );

    ps.setInt(1,idCita);
    ps.setInt(2,idVete);

    rs = ps.executeQuery();

    if(!rs.next()){

        rs.close();
        ps.close();
        con.close();

        response.sendRedirect("listarCitas.jsp");
        return;
    }

    idTutorActual = rs.getInt("id_tutor");
    idMascotaActual = rs.getInt("id_mascota");

    fechaActual = rs.getString("fecha");
    horaActual = rs.getString("hora");

    rs.close();
    ps.close();

    String mensaje = null;

    if("POST".equals(request.getMethod())){

        String nuevaFecha =
            request.getParameter("fecha");

        String nuevaHora =
            request.getParameter("hora");

        String nuevoTutor =
            request.getParameter("id_tutor");

        String nuevaMascota =
            request.getParameter("id_mascota");

        try{

            ps = con.prepareStatement(
                "SELECT COUNT(*) " +
                "FROM citas " +
                "WHERE fecha=? " +
                "AND hora=? " +
                "AND id_vete=? " +
                "AND id_citas<>?"
            );

            ps.setString(1,nuevaFecha);
            ps.setString(2,nuevaHora);
            ps.setInt(3,idVete);
            ps.setInt(4,idCita);

            rs = ps.executeQuery();

            rs.next();

            boolean ocupado =
                rs.getInt(1) > 0;

            rs.close();
            ps.close();

            if(ocupado){

                mensaje =
                    "Ese horario ya está ocupado.";

            }else{

                ps = con.prepareStatement(
                    "UPDATE citas " +
                    "SET fecha=?," +
                    "hora=?," +
                    "id_tutor=?," +
                    "id_mascota=? " +
                    "WHERE id_citas=? " +
                    "AND id_vete=?"
                );

                ps.setString(1,nuevaFecha);
                ps.setString(2,nuevaHora);

                ps.setInt(
                    3,
                    Integer.parseInt(nuevoTutor)
                );

                ps.setInt(
                    4,
                    Integer.parseInt(nuevaMascota)
                );

                ps.setInt(5,idCita);
                ps.setInt(6,idVete);

                ps.executeUpdate();

                ps.close();
                con.close();

                response.sendRedirect(
                    "listarCitas.jsp"
                );

                return;
            }

        }
        catch(Exception e){

            mensaje =
                "Error al actualizar.";

        }

        fechaActual = nuevaFecha;
        horaActual = nuevaHora;

        idTutorActual =
            Integer.parseInt(nuevoTutor);

        idMascotaActual =
            Integer.parseInt(nuevaMascota);
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>

<meta charset="UTF-8">

<title>Editar Cita</title>

<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap"
      rel="stylesheet">

<link rel="stylesheet"
      href="../style.css">

</head>

<body class="dashboard">

<div class="topbar">

    <span class="logo">
        PETIFY
    </span>

    <a href="../logout.jsp"
       class="btn-logout">
        Cerrar sesión
    </a>

</div>

<div class="main-content">

    <a href="listarCitas.jsp"
       class="btn-back">

        ← Volver

    </a>

    <h2 class="page__title">
        Editar Cita
    </h2>

    <% if(mensaje != null){ %>

        <p class="error-msg">
            <%= mensaje %>
        </p>

    <% } %>

    <div class="card"
         style="padding:2rem;">

        <form method="post">

            <div class="form-group">

                <label>
                    Tutor
                </label>

                <div class="input-wrap">

                    <select
                        id="id_tutor"
                        name="id_tutor"
                        class="select-input"
                        onchange="cargarMascotas()">

                        <%
                            ps = con.prepareStatement(
                                "SELECT id_tutor, nom_tutor " +
                                "FROM tutor " +
                                "ORDER BY nom_tutor"
                            );

                            rs = ps.executeQuery();

                            while(rs.next()){

                                int idTutor =
                                    rs.getInt(
                                        "id_tutor"
                                    );
                        %>

                        <option
                            value="<%= idTutor %>"
                            <%= idTutor==idTutorActual ? "selected" : "" %>>

                            <%= esc(rs.getString("nom_tutor")) %>

                        </option>

                        <%
                            }

                            rs.close();
                            ps.close();
                        %>

                    </select>

                </div>

            </div>

            <div class="form-group">

                <label>
                    Mascota
                </label>

                <div class="input-wrap">

                    <select
                        id="id_mascota"
                        name="id_mascota"
                        class="select-input">

                    </select>

                </div>

            </div>

            <div class="form-group">

                <label>
                    Fecha
                </label>

                <div class="input-wrap">

                    <input
                        type="date"
                        name="fecha"
                        value="<%= fechaActual %>">

                </div>

            </div>

            <div class="form-group">

                <label>
                    Hora
                </label>

                <div class="input-wrap">

                    <select
                        name="hora"
                        class="select-input">

                        <%
                            String[] horas = {
                                "09:00:00",
                                "10:00:00",
                                "11:00:00",
                                "12:00:00",
                                "13:00:00",
                                "16:00:00",
                                "17:00:00",
                                "18:00:00"
                            };

                            for(String h : horas){
                        %>

                        <option
                            value="<%= h %>"
                            <%= h.equals(horaActual)
                                ? "selected"
                                : "" %>>

                            <%= h.substring(0,5) %>

                        </option>

                        <% } %>

                    </select>

                </div>

            </div>

            <button
                type="submit"
                class="btn-acceso">

                Guardar Cambios

            </button>

        </form>

    </div>

</div>

<script>

const mascotaSeleccionada =
    <%= idMascotaActual %>;

function cargarMascotas(){

    const tutor =
        document.getElementById(
            "id_tutor"
        ).value;

    const mascotaSelect =
        document.getElementById(
            "id_mascota"
        );

    mascotaSelect.innerHTML = "";

    fetch(
        "getMascotasTutor.jsp?id_tutor=" +
        tutor
    )
    .then(r => r.json())
    .then(mascotas => {

        mascotas.forEach(m => {

            let option =
                document.createElement(
                    "option"
                );

            option.value = m.id;
            option.textContent =
                m.nombre;

            if(
                m.id ==
                mascotaSeleccionada
            ){
                option.selected = true;
            }

            mascotaSelect.appendChild(
                option
            );

        });

    });

}

window.onload =
    cargarMascotas;

</script>

</body>
</html>

<%
    if(con != null && !con.isClosed()){
        con.close();
    }
%>