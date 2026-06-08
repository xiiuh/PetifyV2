<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>

<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");

    Connection con = ds.getConnection();

    int idVete = 0;
    String nomVete = "";

    PreparedStatement ps = con.prepareStatement(
        "SELECT id_vete, nom_vete " +
        "FROM veterinario " +
        "WHERE correo=?"
    );

    ps.setString(1, correo);

    ResultSet rs = ps.executeQuery();

    if(rs.next()){
        idVete = rs.getInt("id_vete");
        nomVete = rs.getString("nom_vete");
    }

    rs.close();
    ps.close();
%>

<!DOCTYPE html>
<html lang="es">
<head>

    <meta charset="UTF-8">

    <title>Petify - Registrar Cita</title>

    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap"
          rel="stylesheet">

    <link rel="stylesheet" href="../style.css">

</head>

<body class="dashboard">

<div class="topbar">

    <span class="logo">PETIFY</span>

    <span class="user-welcome">
        Dr. <%= esc(nomVete) %>
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
        Registrar Cita
    </h2>

    <p class="page-sub">
        Selecciona tutor, mascota, fecha y hora
    </p>

    <input type="hidden"
           id="ID_VETE"
           value="<%= idVete %>">

    <div class="card"
         style="padding:2rem;margin-bottom:1.5rem;">

        <div class="form-group">

            <label for="ID_TUTOR">
                Tutor
            </label>

            <div class="input-wrap">

                <select
                        id="ID_TUTOR"
                        class="select-input"
                        onchange="loadMascotas();">

                    <%
                        ps = con.prepareStatement(
                            "SELECT id_tutor, nom_tutor " +
                            "FROM tutor " +
                            "ORDER BY nom_tutor"
                        );

                        rs = ps.executeQuery();

                        while(rs.next()){
                    %>

                    <option value="<%= rs.getInt("id_tutor") %>">

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

            <label for="ID_MASCOTA">
                Mascota
            </label>

            <div class="input-wrap">

                <select
                        id="ID_MASCOTA"
                        class="select-input">

                </select>

            </div>

        </div>

        <div class="calendar-section"
             style="margin-top:2rem;">

            <label>
                Selecciona una Fecha
            </label>

            <input type="date"
                   id="calendar-input"
                   class="select-input"
                   style="margin-bottom:1.5rem;max-width:300px;">

            <div class="hours-container">

                <label>
                    Horarios Disponibles
                </label>

                <div id="time-buttons"
                     class="time-grid"
                     style="margin-top:.5rem;display:flex;gap:10px;flex-wrap:wrap;">

                </div>

            </div>

            <div style="margin-top:1.5rem;font-size:.95rem;">

                <strong>Selección:</strong>

                <span id="selected-time-span">

                    Ninguna

                </span>

            </div>

        </div>

        <div style="margin-top:2rem;text-align:right;">

            <button
                    type="button"
                    class="btn-submit"
                    onclick="confirmCita()"
                    style="padding:.75rem 2rem;cursor:pointer;">

                Confirmar Cita

            </button>

        </div>

    </div>

</div>

<script src="calendario.js"></script>

</body>
</html>

<%
    con.close();
%>