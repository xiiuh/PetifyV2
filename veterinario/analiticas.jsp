<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*, java.time.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();
    PreparedStatement ps;
    ResultSet rs;

    // ── KPIs ──────────────────────────────────────────────────────────────
    ps = con.prepareStatement(
        "SELECT COALESCE(SUM(total),0) FROM ordenes " +
        "WHERE YEAR(fecha_compra)=YEAR(NOW()) AND MONTH(fecha_compra)=MONTH(NOW())");
    rs = ps.executeQuery(); rs.next();
    double kpiIngresos = rs.getDouble(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM citas " +
        "WHERE YEAR(fecha)=YEAR(NOW()) AND MONTH(fecha)=MONTH(NOW())");
    rs = ps.executeQuery(); rs.next();
    int kpiCitas = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement("SELECT COUNT(*) FROM mascota");
    rs = ps.executeQuery(); rs.next();
    int kpiPacientes = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement("SELECT COUNT(*) FROM productos WHERE cantidad > 0");
    rs = ps.executeQuery(); rs.next();
    int kpiProductos = rs.getInt(1);
    rs.close(); ps.close();

    // ── Últimos 6 meses — etiquetas ────────────────────────────────────────
    String[] MESES_ES = {"Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"};
    LocalDate hoy = LocalDate.now();
    String[] labMeses   = new String[6];
    String[] keysMeses  = new String[6];
    for (int i = 5; i >= 0; i--) {
        LocalDate d = hoy.minusMonths(i);
        labMeses[5-i]  = MESES_ES[d.getMonthValue()-1] + " " + d.getYear();
        keysMeses[5-i] = String.format("%d-%02d", d.getYear(), d.getMonthValue());
    }

    // ── Ingresos por mes ───────────────────────────────────────────────────
    Map<String,Double> mapIngresos = new LinkedHashMap<>();
    for (String k : keysMeses) mapIngresos.put(k, 0.0);
    ps = con.prepareStatement(
        "SELECT DATE_FORMAT(fecha_compra,'%Y-%m') mes, SUM(total) tot " +
        "FROM ordenes WHERE fecha_compra >= DATE_SUB(NOW(), INTERVAL 6 MONTH) " +
        "GROUP BY mes ORDER BY mes");
    rs = ps.executeQuery();
    while (rs.next()) { if (mapIngresos.containsKey(rs.getString("mes"))) mapIngresos.put(rs.getString("mes"), rs.getDouble("tot")); }
    rs.close(); ps.close();

    // ── Citas por mes ──────────────────────────────────────────────────────
    Map<String,Integer> mapCitas = new LinkedHashMap<>();
    for (String k : keysMeses) mapCitas.put(k, 0);
    ps = con.prepareStatement(
        "SELECT DATE_FORMAT(fecha,'%Y-%m') mes, COUNT(*) tot " +
        "FROM citas WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
        "GROUP BY mes ORDER BY mes");
    rs = ps.executeQuery();
    while (rs.next()) { if (mapCitas.containsKey(rs.getString("mes"))) mapCitas.put(rs.getString("mes"), rs.getInt("tot")); }
    rs.close(); ps.close();

    // ── Estado de órdenes ─────────────────────────────────────────────────
    int estPendiente = 0, estConfirmada = 0, estCancelada = 0;
    ps = con.prepareStatement("SELECT estado, COUNT(*) tot FROM ordenes GROUP BY estado");
    rs = ps.executeQuery();
    while (rs.next()) {
        String e = rs.getString("estado");
        int v = rs.getInt("tot");
        if ("pendiente".equals(e))  estPendiente  = v;
        if ("confirmada".equals(e)) estConfirmada = v;
        if ("cancelada".equals(e))  estCancelada  = v;
    }
    rs.close(); ps.close();

    // ── Top 5 productos ────────────────────────────────────────────────────
    List<String>  prodNombres = new ArrayList<>();
    List<Integer> prodVendido = new ArrayList<>();
    ps = con.prepareStatement(
        "SELECT p.nombre, SUM(d.cantidad) tot " +
        "FROM detalle_orden d JOIN productos p ON d.id_producto=p.id_producto " +
        "GROUP BY p.id_producto, p.nombre ORDER BY tot DESC LIMIT 5");
    rs = ps.executeQuery();
    while (rs.next()) { prodNombres.add(rs.getString("nombre")); prodVendido.add(rs.getInt("tot")); }
    rs.close(); ps.close();

    // ── Especies ───────────────────────────────────────────────────────────
    List<String>  espNombres = new ArrayList<>();
    List<Integer> espTotales = new ArrayList<>();
    ps = con.prepareStatement(
        "SELECT especie, COUNT(*) tot FROM mascota GROUP BY especie ORDER BY tot DESC");
    rs = ps.executeQuery();
    while (rs.next()) { espNombres.add(rs.getString("especie")); espTotales.add(rs.getInt("tot")); }
    rs.close(); ps.close();

    // ── Motivos de consulta ────────────────────────────────────────────────
    List<String>  motNombres = new ArrayList<>();
    List<Integer> motTotales = new ArrayList<>();
    ps = con.prepareStatement(
        "SELECT motivo, COUNT(*) tot FROM consultas GROUP BY motivo ORDER BY tot DESC LIMIT 6");
    rs = ps.executeQuery();
    while (rs.next()) { motNombres.add(rs.getString("motivo")); motTotales.add(rs.getInt("tot")); }
    rs.close(); ps.close();

    con.close();

    // ── Helpers para JSON ──────────────────────────────────────────────────
    // Build JS arrays as strings
    StringBuilder jsLabMeses = new StringBuilder("[");
    StringBuilder jsIngresos = new StringBuilder("[");
    StringBuilder jsCitas    = new StringBuilder("[");
    for (int i = 0; i < 6; i++) {
        if (i > 0) { jsLabMeses.append(","); jsIngresos.append(","); jsCitas.append(","); }
        jsLabMeses.append("\"").append(labMeses[i]).append("\"");
        jsIngresos.append(mapIngresos.get(keysMeses[i]));
        jsCitas.append(mapCitas.get(keysMeses[i]));
    }
    jsLabMeses.append("]"); jsIngresos.append("]"); jsCitas.append("]");

    StringBuilder jsProdNom = new StringBuilder("[");
    StringBuilder jsProdVal = new StringBuilder("[");
    for (int i = 0; i < prodNombres.size(); i++) {
        if (i > 0) { jsProdNom.append(","); jsProdVal.append(","); }
        jsProdNom.append("\"").append(prodNombres.get(i).replace("\"","\\\"")).append("\"");
        jsProdVal.append(prodVendido.get(i));
    }
    jsProdNom.append("]"); jsProdVal.append("]");

    StringBuilder jsEspNom = new StringBuilder("[");
    StringBuilder jsEspVal = new StringBuilder("[");
    for (int i = 0; i < espNombres.size(); i++) {
        if (i > 0) { jsEspNom.append(","); jsEspVal.append(","); }
        jsEspNom.append("\"").append(espNombres.get(i).replace("\"","\\\"")).append("\"");
        jsEspVal.append(espTotales.get(i));
    }
    jsEspNom.append("]"); jsEspVal.append("]");

    StringBuilder jsMotNom = new StringBuilder("[");
    StringBuilder jsMotVal = new StringBuilder("[");
    for (int i = 0; i < motNombres.size(); i++) {
        if (i > 0) { jsMotNom.append(","); jsMotVal.append(","); }
        jsMotNom.append("\"").append(motNombres.get(i).replace("\"","\\\"")).append("\"");
        jsMotVal.append(motTotales.get(i));
    }
    jsMotNom.append("]"); jsMotVal.append("]");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analíticas – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1rem;
            margin-bottom: 1.5rem;
        }
        .kpi-card {
            background: var(--white);
            border-radius: var(--radius-card);
            padding: 1.4rem 1.6rem;
            box-shadow: var(--shadow);
            display: flex;
            flex-direction: column;
            gap: .3rem;
        }
        .kpi-label {
            font-size: .78rem;
            font-weight: 600;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: .06em;
        }
        .kpi-value {
            font-size: 2rem;
            font-weight: 700;
            color: var(--teal-dark);
            line-height: 1.1;
        }
        .kpi-sub {
            font-size: .8rem;
            color: var(--muted);
        }
        .kpi-icon {
            font-size: 1.4rem;
            margin-bottom: .2rem;
        }
        .charts-grid-main {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 1rem;
            margin-bottom: 1rem;
        }
        .charts-grid-half {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
            margin-bottom: 1rem;
        }
        .charts-grid-third {
            display: grid;
            grid-template-columns: 1fr 2fr;
            gap: 1rem;
            margin-bottom: 1rem;
        }
        .chart-card {
            background: var(--white);
            border-radius: var(--radius-card);
            padding: 1.4rem 1.6rem;
            box-shadow: var(--shadow);
        }
        .chart-title {
            font-size: .9rem;
            font-weight: 700;
            color: var(--teal-dark);
            margin-bottom: 1rem;
            padding-bottom: .6rem;
            border-bottom: 2px solid var(--teal-pale);
        }
        .chart-wrap { position: relative; }
        @media (max-width: 900px) {
            .kpi-grid { grid-template-columns: repeat(2,1fr); }
            .charts-grid-main,
            .charts-grid-half,
            .charts-grid-third { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <div style="margin-bottom:1.5rem;">
            <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="btn-back" style="margin:0 0 .5rem;">← Volver</a>
            <h2 class="page__title" style="margin:.5rem 0 .2rem;">Analíticas</h2>
            <p class="page-sub">Resumen de actividad clínica y comercial</p>
        </div>

        <%-- KPIs --%>
        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-label">Ingresos este mes</div>
                <div class="kpi-value">$<%= String.format("%,.2f", kpiIngresos) %></div>
                <div class="kpi-sub">Órdenes confirmadas y pendientes</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Citas este mes</div>
                <div class="kpi-value"><%= kpiCitas %></div>
                <div class="kpi-sub">Consultas agendadas</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Pacientes registrados</div>
                <div class="kpi-value"><%= kpiPacientes %></div>
                <div class="kpi-sub">Total de mascotas en el sistema</div>
            </div>
            <div class="kpi-card">
                <div class="kpi-label">Productos en stock</div>
                <div class="kpi-value"><%= kpiProductos %></div>
                <div class="kpi-sub">Con cantidad disponible</div>
            </div>
        </div>

        <%-- Ingresos + Estado órdenes --%>
        <div class="charts-grid-main">
            <div class="chart-card">
                <div class="chart-title">Ingresos últimos 6 meses</div>
                <div class="chart-wrap" style="height:260px;">
                    <canvas id="chartIngresos"></canvas>
                </div>
            </div>
            <div class="chart-card">
                <div class="chart-title">Estado de órdenes</div>
                <div class="chart-wrap" style="height:260px;">
                    <canvas id="chartEstado"></canvas>
                </div>
            </div>
        </div>

        <%-- Top productos + Citas por mes --%>
        <div class="charts-grid-half">
            <div class="chart-card">
                <div class="chart-title">Top 5 productos más vendidos</div>
                <div class="chart-wrap" style="height:240px;">
                    <canvas id="chartProductos"></canvas>
                </div>
            </div>
            <div class="chart-card">
                <div class="chart-title">Citas últimos 6 meses</div>
                <div class="chart-wrap" style="height:240px;">
                    <canvas id="chartCitas"></canvas>
                </div>
            </div>
        </div>

        <%-- Especies + Motivos de consulta --%>
        <div class="charts-grid-third">
            <div class="chart-card">
                <div class="chart-title">Especies atendidas</div>
                <div class="chart-wrap" style="height:260px;">
                    <canvas id="chartEspecies"></canvas>
                </div>
            </div>
            <div class="chart-card">
                <div class="chart-title">Motivos de consulta más frecuentes</div>
                <div class="chart-wrap" style="height:260px;">
                    <canvas id="chartMotivos"></canvas>
                </div>
            </div>
        </div>
    </div>

<script>
    Chart.defaults.font.family = "'DM Sans', sans-serif";
    Chart.defaults.color = '#6b8070';

    const TEAL_DARK  = '#1a3d35';
    const TEAL_MID   = '#2d5a4a';
    const TEAL_LIGHT = '#4a8c75';
    const TEAL_PALE  = '#edf5f0';
    const ORANGE     = '#c8521a';
    const GOLD       = '#d4a843';

    // ── Ingresos ────────────────────────────────────────────────────────────
    (function() {
        const ctx = document.getElementById('chartIngresos').getContext('2d');
        const grad = ctx.createLinearGradient(0, 0, 0, 260);
        grad.addColorStop(0, 'rgba(26,61,53,.18)');
        grad.addColorStop(1, 'rgba(26,61,53,.01)');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: <%= jsLabMeses %>,
                datasets: [{
                    label: 'Ingresos ($)',
                    data: <%= jsIngresos %>,
                    borderColor: TEAL_DARK,
                    backgroundColor: grad,
                    borderWidth: 2.5,
                    pointBackgroundColor: TEAL_DARK,
                    pointRadius: 4,
                    fill: true,
                    tension: .35
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,.05)' },
                         ticks: { callback: v => '$' + v.toLocaleString() } },
                    x: { grid: { display: false } }
                }
            }
        });
    })();

    // ── Estado órdenes ──────────────────────────────────────────────────────
    new Chart(document.getElementById('chartEstado'), {
        type: 'doughnut',
        data: {
            labels: ['Pendiente', 'Confirmada', 'Cancelada'],
            datasets: [{
                data: [<%= estPendiente %>, <%= estConfirmada %>, <%= estCancelada %>],
                backgroundColor: [GOLD, TEAL_LIGHT, ORANGE],
                borderWidth: 0,
                hoverOffset: 6
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'bottom', labels: { padding: 16, boxWidth: 12 } }
            },
            cutout: '60%'
        }
    });

    // ── Top productos ───────────────────────────────────────────────────────
    new Chart(document.getElementById('chartProductos'), {
        type: 'bar',
        data: {
            labels: <%= jsProdNom %>,
            datasets: [{
                label: 'Unidades vendidas',
                data: <%= jsProdVal %>,
                backgroundColor: [TEAL_DARK, TEAL_MID, TEAL_LIGHT, '#6baa90', '#9fcfb8'],
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { beginAtZero: true, grid: { color: 'rgba(0,0,0,.05)' },
                     ticks: { precision: 0 } },
                y: { grid: { display: false } }
            }
        }
    });

    // ── Citas por mes ───────────────────────────────────────────────────────
    new Chart(document.getElementById('chartCitas'), {
        type: 'bar',
        data: {
            labels: <%= jsLabMeses %>,
            datasets: [{
                label: 'Citas',
                data: <%= jsCitas %>,
                backgroundColor: TEAL_DARK,
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,.05)' },
                     ticks: { precision: 0 } },
                x: { grid: { display: false } }
            }
        }
    });

    // ── Especies ────────────────────────────────────────────────────────────
    new Chart(document.getElementById('chartEspecies'), {
        type: 'pie',
        data: {
            labels: <%= jsEspNom %>,
            datasets: [{
                data: <%= jsEspVal %>,
                backgroundColor: [TEAL_DARK, TEAL_LIGHT, GOLD, ORANGE, '#9fcfb8', '#6baa90'],
                borderWidth: 0,
                hoverOffset: 6
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: {
                legend: { position: 'bottom', labels: { padding: 12, boxWidth: 12 } }
            }
        }
    });

    // ── Motivos de consulta ─────────────────────────────────────────────────
    new Chart(document.getElementById('chartMotivos'), {
        type: 'bar',
        data: {
            labels: <%= jsMotNom %>,
            datasets: [{
                label: 'Consultas',
                data: <%= jsMotVal %>,
                backgroundColor: TEAL_LIGHT,
                borderRadius: 6,
                borderSkipped: false
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,.05)' },
                     ticks: { precision: 0 } },
                x: { grid: { display: false } }
            }
        }
    });
</script>
</body>
</html>
