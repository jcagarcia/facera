require 'grape'
require_relative 'introspection'

module Facera
  class DashboardAPI < ::Grape::API
    format :binary

    helpers do
      def swagger_ui(title, spec_url)
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{title} — Facera</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
            <style>
              *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
              :root {
                --bg: #0f0f13;
                --surface: #17171f;
                --border: rgba(255,255,255,0.07);
                --accent1: #7c6af7;
                --accent2: #5eead4;
                --muted: #8888aa;
                --text: #e8e8f0;
                --grad: linear-gradient(135deg, #7c6af7 0%, #5eead4 50%, #f472b6 100%);
              }
              body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; min-height: 100vh; }
              .top-bar {
                background: var(--surface);
                border-bottom: 1px solid var(--border);
                padding: 14px 32px;
                display: flex;
                align-items: center;
                gap: 16px;
                position: relative;
                overflow: hidden;
              }
              .top-bar::before {
                content: '';
                position: absolute;
                inset: 0;
                background: radial-gradient(ellipse 60% 100% at 30% 50%, rgba(124,106,247,0.12) 0%, transparent 70%);
                pointer-events: none;
              }
              .top-bar-logo {
                width: 36px; height: 36px;
                background: var(--grad);
                border-radius: 10px;
                display: flex; align-items: center; justify-content: center;
                font-size: 18px;
                box-shadow: 0 0 20px rgba(124,106,247,0.3);
                flex-shrink: 0;
              }
              .top-bar-title { font-size: 15px; font-weight: 600; color: var(--text); }
              .top-bar-sub { font-size: 12px; color: var(--muted); margin-top: 1px; }
              .back-link {
                margin-left: auto;
                font-size: 12px;
                color: var(--accent1);
                text-decoration: none;
                border: 1px solid rgba(124,106,247,0.3);
                padding: 5px 12px;
                border-radius: 7px;
                transition: background 0.15s;
                position: relative;
              }
              .back-link:hover { background: rgba(124,106,247,0.1); }
              /* Swagger UI dark overrides */
              .swagger-ui { background: var(--bg) !important; }
              .swagger-ui .topbar { display: none !important; }
              .swagger-ui .info { padding: 20px 0 10px; }
              .swagger-ui .info .title { color: var(--text) !important; }
              .swagger-ui .info p, .swagger-ui .info li { color: var(--muted) !important; }
              .swagger-ui .scheme-container { background: var(--surface) !important; border-bottom: 1px solid var(--border) !important; box-shadow: none !important; }
              .swagger-ui .opblock-tag { color: var(--text) !important; border-bottom: 1px solid var(--border) !important; }
              .swagger-ui .opblock { border-radius: 8px !important; margin-bottom: 6px !important; border: 1px solid var(--border) !important; }
              .swagger-ui .opblock .opblock-summary { border-radius: 8px !important; }
              .swagger-ui .opblock.opblock-get { background: rgba(94,234,212,0.05) !important; border-color: rgba(94,234,212,0.2) !important; }
              .swagger-ui .opblock.opblock-post { background: rgba(124,106,247,0.05) !important; border-color: rgba(124,106,247,0.2) !important; }
              .swagger-ui .opblock.opblock-put, .swagger-ui .opblock.opblock-patch { background: rgba(251,191,36,0.05) !important; border-color: rgba(251,191,36,0.2) !important; }
              .swagger-ui .opblock.opblock-delete { background: rgba(244,114,182,0.05) !important; border-color: rgba(244,114,182,0.2) !important; }
              .swagger-ui .opblock-body { background: var(--surface) !important; }
              .swagger-ui section.models { background: var(--surface) !important; border: 1px solid var(--border) !important; border-radius: 8px !important; }
              .swagger-ui section.models h4 { color: var(--text) !important; }
              .swagger-ui .model-box { background: var(--bg) !important; }
              .swagger-ui .model { color: var(--text) !important; }
              .swagger-ui textarea, .swagger-ui input[type=text], .swagger-ui input[type=email], .swagger-ui input[type=password] {
                background: var(--bg) !important; color: var(--text) !important; border: 1px solid var(--border) !important;
              }
              .swagger-ui select { background: var(--surface) !important; color: var(--text) !important; border: 1px solid var(--border) !important; }
              .swagger-ui .btn { border-radius: 6px !important; }
              .swagger-ui .btn.execute { background: var(--accent1) !important; border-color: var(--accent1) !important; }
              .swagger-ui .response-col_status { color: var(--accent2) !important; }
              .swagger-ui table thead tr th, .swagger-ui table thead tr td { color: var(--muted) !important; border-bottom: 1px solid var(--border) !important; }
              .swagger-ui .parameter__name { color: var(--text) !important; }
              .swagger-ui .parameter__type { color: var(--accent2) !important; }
              .swagger-ui .tab li { color: var(--muted) !important; }
              .swagger-ui .tab li.active { color: var(--text) !important; }
              #swagger-ui { max-width: 1100px; margin: 0 auto; padding: 0 24px 60px; }
            </style>
          </head>
          <body>
            <div class="top-bar">
              <div class="top-bar-logo">&#9671;</div>
              <div>
                <div class="top-bar-title">#{title}</div>
                <div class="top-bar-sub">OpenAPI 3.0 — Facera v#{Facera::VERSION}</div>
              </div>
              <a class="back-link" href="/facera">&larr; Dashboard</a>
            </div>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
            <script>
              SwaggerUIBundle({
                url: '#{spec_url}',
                dom_id: '#swagger-ui',
                presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
                layout: 'BaseLayout',
                deepLinking: true,
                defaultModelsExpandDepth: 1,
                defaultModelExpandDepth: 2
              });
            </script>
          </body>
          </html>
        HTML
      end

      def spa_shell
        base = Facera.configuration.base_path

        html = <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Facera Dashboard</title>
            <style>
              *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

              :root {
                --bg: #0f0f13;
                --surface: #17171f;
                --surface2: #1e1e2a;
                --border: rgba(255,255,255,0.07);
                --text: #e8e8f0;
                --muted: #8888aa;
                --accent1: #7c6af7;
                --accent2: #5eead4;
                --accent3: #f472b6;
                --grad: linear-gradient(135deg, #7c6af7 0%, #5eead4 50%, #f472b6 100%);
              }

              *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
              body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-size: 14px; line-height: 1.6; min-height: 100vh; }

              /* Hero */
              .hero { background: var(--surface); border-bottom: 1px solid var(--border); padding: 36px 40px 32px; position: relative; overflow: hidden; }
              .hero::before { content: ''; position: absolute; inset: 0; background: radial-gradient(ellipse 80% 60% at 50% -10%, rgba(124,106,247,0.18) 0%, transparent 70%); pointer-events: none; }
              .hero-inner { max-width: 1100px; margin: 0 auto; display: flex; align-items: center; gap: 20px; position: relative; }
              .logo { width: 48px; height: 48px; background: var(--grad); border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 22px; flex-shrink: 0; box-shadow: 0 0 32px rgba(124,106,247,0.35); cursor: pointer; }
              .hero-text h1 { font-size: 24px; font-weight: 700; background: var(--grad); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; letter-spacing: -0.5px; cursor: pointer; }
              .hero-text p { color: var(--muted); margin-top: 2px; font-size: 13px; }
              .version-badge { margin-left: auto; background: rgba(124,106,247,0.15); border: 1px solid rgba(124,106,247,0.3); color: var(--accent1); padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; letter-spacing: 0.5px; }

              /* Nav */
              .nav-bar { max-width: 1100px; margin: 0 auto; padding: 12px 40px; display: flex; gap: 6px; flex-wrap: wrap; border-bottom: 1px solid var(--border); }
              .nav-link { display: inline-flex; align-items: center; gap: 6px; padding: 5px 12px; border-radius: 7px; border: 1px solid var(--border); color: var(--muted); text-decoration: none; font-size: 12px; font-weight: 500; transition: all 0.15s; cursor: pointer; background: none; }
              .nav-link:hover, .nav-link.active { border-color: var(--accent1); color: var(--accent1); background: rgba(124,106,247,0.08); }
              .nav-link .dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }

              /* Breadcrumb */
              .breadcrumb { max-width: 1100px; margin: 0 auto; padding: 14px 40px 0; display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--muted); }
              .breadcrumb a { color: var(--accent1); text-decoration: none; cursor: pointer; }
              .breadcrumb a:hover { text-decoration: underline; }
              .breadcrumb .sep { color: var(--border); }

              /* Main */
              .main { max-width: 1100px; margin: 0 auto; padding: 24px 40px 60px; }

              /* Section headers */
              .section-header { display: flex; align-items: center; gap: 10px; margin: 28px 0 16px; }
              .section-header h2 { font-size: 15px; font-weight: 600; color: var(--text); }
              .section-line { flex: 1; height: 1px; background: var(--border); }
              .section-count { font-size: 12px; color: var(--muted); background: var(--surface2); border: 1px solid var(--border); padding: 2px 8px; border-radius: 10px; }

              /* Cards */
              .cards-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 14px; }
              .card { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 20px; transition: border-color 0.2s, transform 0.2s; position: relative; overflow: hidden; }
              .card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px; background: var(--grad); opacity: 0; transition: opacity 0.2s; }
              .card:hover { border-color: rgba(124,106,247,0.4); transform: translateY(-2px); }
              .card:hover::before { opacity: 1; }
              .card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
              .card-title { font-size: 15px; font-weight: 600; color: var(--text); }
              .pill { font-size: 11px; padding: 2px 8px; border-radius: 20px; background: rgba(94,234,212,0.12); border: 1px solid rgba(94,234,212,0.25); color: var(--accent2); font-weight: 500; }
              .card-desc { color: var(--muted); font-size: 13px; margin-bottom: 12px; min-height: 20px; }
              .meta-row { display: flex; align-items: center; justify-content: space-between; padding: 5px 0; border-top: 1px solid var(--border); }
              .meta-label { color: var(--muted); font-size: 12px; }
              .meta-value { font-size: 12px; color: var(--text); }
              .meta-value a { color: var(--accent1); text-decoration: none; cursor: pointer; }
              .meta-value a:hover { text-decoration: underline; }
              .mono { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 11px; }
              .badge { display: inline-block; padding: 1px 6px; border-radius: 4px; font-size: 10px; background: rgba(244,114,182,0.12); border: 1px solid rgba(244,114,182,0.25); color: var(--accent3); margin-right: 2px; }
              .badge.muted { background: var(--surface2); border-color: var(--border); color: var(--muted); }
              .badge.teal { background: rgba(94,234,212,0.10); border-color: rgba(94,234,212,0.25); color: var(--accent2); }
              .badge.purple { background: rgba(124,106,247,0.10); border-color: rgba(124,106,247,0.25); color: var(--accent1); }
              .card-actions { display: flex; gap: 8px; margin-top: 14px; }
              .btn { flex: 1; text-align: center; padding: 6px 10px; border-radius: 8px; font-size: 12px; font-weight: 500; text-decoration: none; transition: all 0.15s; cursor: pointer; border: none; }
              .btn-ghost { border: 1px solid var(--border); color: var(--muted); background: none; }
              .btn-ghost:hover { border-color: var(--accent1); color: var(--accent1); }
              .btn-primary { background: rgba(124,106,247,0.15); border: 1px solid rgba(124,106,247,0.35); color: var(--accent1); }
              .btn-primary:hover { background: rgba(124,106,247,0.28); }

              /* Table */
              .table-wrap { border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }
              table { width: 100%; border-collapse: collapse; }
              thead tr { background: var(--surface2); }
              th { text-align: left; padding: 10px 16px; font-size: 11px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: 0.6px; border-bottom: 1px solid var(--border); }
              td { padding: 11px 16px; font-size: 13px; border-bottom: 1px solid var(--border); }
              tr:last-child td { border-bottom: none; }
              tbody tr { background: var(--surface); transition: background 0.15s; }
              tbody tr:hover { background: var(--surface2); }
              td.mono { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 12px; color: var(--accent2); }
              .tbl-link { color: var(--accent1); text-decoration: none; font-size: 12px; cursor: pointer; }
              .tbl-link:hover { text-decoration: underline; }

              /* Detail page */
              .detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
              @media (max-width: 700px) { .detail-grid { grid-template-columns: 1fr; } }
              .detail-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 18px; }
              .detail-card h3 { font-size: 13px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 14px; }
              .detail-row { display: flex; justify-content: space-between; align-items: flex-start; padding: 6px 0; border-top: 1px solid var(--border); gap: 12px; }
              .detail-row:first-of-type { border-top: none; }
              .detail-key { color: var(--muted); font-size: 12px; flex-shrink: 0; }
              .detail-val { font-size: 12px; color: var(--text); text-align: right; word-break: break-all; }
              .detail-val.mono { font-family: 'SF Mono', 'Fira Code', monospace; color: var(--accent2); }
              .cap-list { display: flex; flex-direction: column; gap: 6px; }
              .cap-item { background: var(--surface2); border: 1px solid var(--border); border-radius: 8px; padding: 10px 12px; }
              .cap-item-header { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
              .cap-name { font-weight: 600; font-size: 13px; }
              .cap-type { font-size: 10px; padding: 1px 6px; border-radius: 4px; background: rgba(124,106,247,0.12); border: 1px solid rgba(124,106,247,0.25); color: var(--accent1); }
              .cap-meta { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 4px; }
              .attr-list { display: flex; flex-direction: column; gap: 4px; }
              .attr-item { display: flex; align-items: center; gap: 6px; padding: 5px 8px; background: var(--surface2); border-radius: 6px; font-size: 12px; }
              .attr-name { font-family: 'SF Mono', 'Fira Code', monospace; color: var(--accent2); }
              .attr-type { color: var(--muted); font-size: 11px; }

              /* Footer */
              .footer { border-top: 1px solid var(--border); padding: 20px 40px; text-align: center; color: var(--muted); font-size: 12px; }
              .footer a { color: var(--accent1); text-decoration: none; }
              .footer a:hover { text-decoration: underline; }

              /* Audience API cards */
              .api-card { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; transition: border-color 0.2s, transform 0.2s; }
              .api-card:hover { border-color: rgba(124,106,247,0.4); transform: translateY(-2px); }
              .api-card-header { padding: 18px 20px 14px; display: flex; align-items: flex-start; gap: 14px; }
              .api-card-icon { width: 38px; height: 38px; border-radius: 10px; background: var(--grad); display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; }
              .api-card-title { font-size: 16px; font-weight: 700; color: var(--text); }
              .api-card-path { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 11px; color: var(--accent2); margin-top: 2px; }
              .api-card-desc { color: var(--muted); font-size: 12px; margin-top: 4px; }
              .api-card-resources { display: flex; gap: 6px; flex-wrap: wrap; padding: 0 20px 12px; }
              .resource-pill { font-size: 11px; padding: 3px 10px; border-radius: 20px; background: rgba(94,234,212,0.1); border: 1px solid rgba(94,234,212,0.25); color: var(--accent2); font-family: 'SF Mono', 'Fira Code', monospace; }
              .api-cores { border-top: 1px solid var(--border); }
              .api-core-row { display: flex; align-items: center; gap: 10px; padding: 10px 20px; border-bottom: 1px solid var(--border); }
              .api-core-row:last-child { border-bottom: none; }
              .api-core-name { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 12px; color: var(--accent1); min-width: 80px; cursor: pointer; }
              .api-core-name:hover { text-decoration: underline; }
              .api-core-desc { color: var(--muted); font-size: 12px; flex: 1; }
              .api-core-badges { display: flex; gap: 4px; flex-wrap: wrap; }
              .api-card-actions { display: flex; gap: 8px; padding: 12px 20px; border-top: 1px solid var(--border); background: rgba(255,255,255,0.02); }

              /* Empty / Loading */
              .empty { text-align: center; padding: 40px; color: var(--muted); }
              .spinner { display: inline-block; width: 20px; height: 20px; border: 2px solid var(--border); border-top-color: var(--accent1); border-radius: 50%; animation: spin 0.6s linear infinite; }
              @keyframes spin { to { transform: rotate(360deg); } }
              .loading { display: flex; align-items: center; justify-content: center; gap: 10px; padding: 60px; color: var(--muted); }
            </style>
          </head>
          <body>
            <div class="hero">
              <div class="hero-inner">
                <div class="logo" onclick="navigate('/')">&#9671;</div>
                <div class="hero-text">
                  <h1 onclick="navigate('/')">Facera Dashboard</h1>
                  <p>Facet-based API framework &mdash; auto-mounted endpoints &amp; introspection</p>
                </div>
                <span class="version-badge">v#{Facera::VERSION}</span>
              </div>
            </div>

            <nav>
              <div class="nav-bar">
                <button class="nav-link" id="nav-home" onclick="navigate('/')"><span class="dot"></span>Overview</button>
                <button class="nav-link" id="nav-apis" onclick="navigate('/apis')"><span class="dot"></span>APIs</button>
                <button class="nav-link" id="nav-facets" onclick="navigate('/facets')"><span class="dot"></span>Facets</button>
                <button class="nav-link" id="nav-cores" onclick="navigate('/cores')"><span class="dot"></span>Cores</button>
              </div>
            </nav>

            <div id="breadcrumb-bar"></div>
            <main class="main" id="app"></main>

            <footer class="footer">
              Facera v#{Facera::VERSION} &mdash; <a href="https://github.com/jcagarcia/facera" target="_blank">github.com/jcagarcia/facera</a>
            </footer>

            <script>
              const BASE_API = '#{base}/facera';

              // --- Router ---
              const routes = [];
              function addRoute(pattern, handler) { routes.push({ pattern: pattern, handler: handler }); }

              function navigate(path, push) {
                if (push !== false) history.pushState({}, '', '/facera' + path);
                var app = document.getElementById('app');
                for (var i = 0; i < routes.length; i++) {
                  var m = path.match(routes[i].pattern);
                  if (m) { routes[i].handler(m, app); return; }
                }
              }

              window.addEventListener('popstate', function() {
                var path = location.pathname.replace('/facera', '') || '/';
                navigate(path, false);
              });

              // --- Nav active state ---
              function setNav(id) {
                document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
                const el = document.getElementById(id);
                if (el) el.classList.add('active');
              }

              function setBreadcrumb(parts) {
                const bar = document.getElementById('breadcrumb-bar');
                if (!parts.length) { bar.innerHTML = ''; return; }
                const inner = parts.map((p, i) =>
                  i < parts.length - 1
                    ? `<a onclick="navigate('${p.href}')">${p.label}</a><span class="sep"> / </span>`
                    : `<span>${p.label}</span>`
                ).join('');
                bar.innerHTML = `<div class="breadcrumb">${inner}</div>`;
              }

              // --- API helpers ---
              async function apiFetch(path) {
                const res = await fetch(BASE_API + path, { headers: { 'Accept': 'application/json' } });
                if (!res.ok) throw new Error(`${res.status} ${res.statusText} (${BASE_API + path})`);
                return res.json();
              }

              function loading(el) {
                el.innerHTML = '<div class="loading"><span class="spinner"></span> Loading...</div>';
              }

              // --- Shared renderers ---
              function sectionHeader(title, count) {
                const cnt = count !== undefined ? `<span class="section-count">${count}</span>` : '';
                return `<div class="section-header"><h2>${title}</h2>${cnt}<div class="section-line"></div></div>`;
              }

              function badgeList(items, cls = '') {
                if (!items || items === 'all') return `<span class="badge ${cls || 'purple'}">all</span>`;
                if (!Array.isArray(items) || !items.length) return '<span class="badge muted">none</span>';
                return items.map(i => `<span class="badge ${cls}">${i}</span>`).join(' ');
              }

              // --- Overview ---
              addRoute(new RegExp('^[/]?$'), async (_, el) => {
                setNav('nav-home');
                setBreadcrumb([]);
                loading(el);
                try {
                  const [audiences, cores] = await Promise.all([
                    apiFetch('/audiences'),
                    apiFetch('/cores')
                  ]);

                  const apiCards = audiences.map(a => {
                    const resources = (a.resources || []).map(r =>
                      `<span class="resource-pill">/${r}</span>`
                    ).join('');

                    const coreRows = (a.facets || []).map(f => {
                      const capBadge = f.capabilities.total === 'all'
                        ? '<span class="badge purple">all caps</span>'
                        : `<span class="badge muted">${f.capabilities.total} caps</span>`;
                      const auditBadge = f.audit_logging ? '<span class="badge teal">audit</span>' : '';
                      const verbosity = f.error_verbosity ? `<span class="badge muted">${f.error_verbosity} errors</span>` : '';
                      return `
                        <div class="api-core-row">
                          <span class="api-core-name" onclick="navigate('/cores/${f.core}')">${f.core}</span>
                          <span class="api-core-desc">${f.description || ''}</span>
                          <div class="api-core-badges">${capBadge}${auditBadge}${verbosity}</div>
                        </div>`;
                    }).join('');

                    return `
                      <div class="api-card">
                        <div class="api-card-header">
                          <div class="api-card-icon">&#9671;</div>
                          <div style="flex:1; min-width:0;">
                            <div class="api-card-title">${a.name}</div>
                            <div class="api-card-path">${a.path}</div>
                          </div>
                        </div>
                        ${resources ? `<div class="api-card-resources">${resources}</div>` : ''}
                        <div class="api-cores">${coreRows}</div>
                        <div class="api-card-actions">
                          <a href="/facera/openapi/${a.name}" class="btn btn-ghost">OpenAPI</a>
                          <button class="btn btn-primary" onclick="navigate('/apis/${a.name}')">Details</button>
                        </div>
                      </div>`;
                  }).join('');

                  const coreRows = cores.map(c => `
                    <tr>
                      <td class="mono">${c.name}</td>
                      <td>${(c.entities || []).length}</td>
                      <td>${(c.capabilities || []).length}</td>
                      <td>${(c.invariants || []).length}</td>
                      <td><span class="tbl-link" onclick="navigate('/cores/${c.name}')">inspect &rarr;</span></td>
                    </tr>`).join('');

                  el.innerHTML = `
                    ${sectionHeader('APIs', audiences.length)}
                    ${audiences.length ? `<div class="cards-grid">${apiCards}</div>` : '<div class="empty">No APIs mounted yet.</div>'}
                    ${sectionHeader('Cores', cores.length)}
                    ${cores.length ? `
                      <div class="table-wrap"><table>
                        <thead><tr><th>Name</th><th>Entities</th><th>Capabilities</th><th>Invariants</th><th></th></tr></thead>
                        <tbody>${coreRows}</tbody>
                      </table></div>` : '<div class="empty">No cores registered yet.</div>'}`;
                } catch(e) {
                  console.error('[Facera dashboard]', e);
                  el.innerHTML = `<div class="empty">Failed to load dashboard data: ${e.message}</div>`;
                }
              });

              // --- APIs list ---
              addRoute(new RegExp('^/apis$'), async (_, el) => {
                setNav('nav-apis');
                setBreadcrumb([{ href: '/apis', label: 'APIs' }]);
                loading(el);
                let audiences;
                try { audiences = await apiFetch('/audiences'); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }

                const rows = audiences.map(a => {
                  const resources = (a.resources || []).map(r => `<span class="badge teal">/${r}</span>`).join(' ');
                  const cores = (a.cores || []).map(c => `<span class="badge purple">${c}</span>`).join(' ');
                  return `<tr>
                    <td><span class="tbl-link" onclick="navigate('/apis/${a.name}')">${a.name}</span></td>
                    <td class="mono">${a.path}</td>
                    <td>${cores}</td>
                    <td>${resources}</td>
                    <td><a href="/facera/openapi/${a.name}" class="tbl-link">OpenAPI &rarr;</a></td>
                  </tr>`;
                }).join('');

                el.innerHTML = `
                  ${sectionHeader('APIs', audiences.length)}
                  <div class="table-wrap"><table>
                    <thead><tr><th>Audience</th><th>Path</th><th>Cores</th><th>Resources</th><th></th></tr></thead>
                    <tbody>${rows}</tbody>
                  </table></div>`;
              });

              // --- API detail ---
              addRoute(new RegExp('^/apis/([^/]+)$'), async ([, name], el) => {
                setNav('nav-apis');
                setBreadcrumb([{ href: '/apis', label: 'APIs' }, { label: name }]);
                loading(el);
                let audiences;
                try { audiences = await apiFetch('/audiences'); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }
                const a = audiences.find(x => String(x.name) === name);
                if (!a) { el.innerHTML = `<div class="empty">API "${name}" not found.</div>`; return; }

                const facetDetails = (a.facets || []).map(f => {
                  const allowed = f.capabilities.allowed === 'all'
                    ? '<span class="badge purple">all</span>'
                    : badgeList(f.capabilities.allowed, 'purple');
                  const denied = badgeList(f.capabilities.denied, 'muted');
                  return `
                    <div class="detail-card">
                      <h3><span class="tbl-link" onclick="navigate('/cores/${f.core}')">${f.core}</span> core</h3>
                      <div class="detail-row"><span class="detail-key">Description</span><span class="detail-val">${f.description || '—'}</span></div>
                      <div class="detail-row"><span class="detail-key">Capabilities allowed</span><span class="detail-val">${allowed}</span></div>
                      <div class="detail-row"><span class="detail-key">Capabilities denied</span><span class="detail-val">${denied}</span></div>
                      <div class="detail-row"><span class="detail-key">Error verbosity</span><span class="detail-val">${f.error_verbosity || '—'}</span></div>
                      <div class="detail-row"><span class="detail-key">Audit logging</span><span class="detail-val">${f.audit_logging ? '<span class="badge teal">enabled</span>' : '<span class="badge muted">disabled</span>'}</span></div>
                    </div>`;
                }).join('');

                const resources = (a.resources || []).map(r => `<span class="resource-pill">/${r}</span>`).join('');

                el.innerHTML = `
                  <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px;">
                    <div>
                      <h2 style="font-size:20px; font-weight:700;">${a.name}</h2>
                      <div style="margin-top:6px; display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
                        <span style="font-family:'SF Mono','Fira Code',monospace; font-size:12px; color:var(--accent2);">${a.path}</span>
                        ${resources}
                      </div>
                    </div>
                    <a href="/facera/openapi/${a.name}" class="btn btn-primary" style="flex:0; white-space:nowrap;">View OpenAPI &rarr;</a>
                  </div>
                  <div class="detail-grid">${facetDetails}</div>`;
              });

              // --- Facets list ---
              addRoute(new RegExp('^/facets$'), async (_, el) => {
                setNav('nav-facets');
                setBreadcrumb([{ href: '/facets', label: 'Facets' }]);
                loading(el);
                let facets;
                try { facets = await apiFetch('/facets'); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }

                const rows = facets.map(f => {
                  const capCount = f.capabilities.total;
                  return `<tr>
                    <td><span class="tbl-link" onclick="navigate('/facets/${f.name}')">${f.name}</span></td>
                    <td><span class="tbl-link" onclick="navigate('/cores/${f.core}')">${f.core}</span></td>
                    <td>${capCount}</td>
                    <td>${f.format || 'json'}</td>
                    <td>${f.error_verbosity || '—'}</td>
                    <td>
                      <a href="/facera/openapi/${f.name}" class="tbl-link">OpenAPI &rarr;</a>
                    </td>
                  </tr>`;
                }).join('');

                el.innerHTML = `
                  ${sectionHeader('Facets', facets.length)}
                  <div class="table-wrap"><table>
                    <thead><tr><th>Name</th><th>Core</th><th>Capabilities</th><th>Format</th><th>Error verbosity</th><th></th></tr></thead>
                    <tbody>${rows}</tbody>
                  </table></div>`;
              });

              // --- Facet detail ---
              addRoute(new RegExp('^/facets/([^/]+)$'), async ([, name], el) => {
                setNav('nav-facets');
                setBreadcrumb([{ href: '/facets', label: 'Facets' }, { label: name }]);
                loading(el);
                let f;
                try { f = await apiFetch(`/facets/${name}`); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }

                const allowed = f.capabilities.allowed === 'all'
                  ? '<span class="badge purple">all</span>'
                  : badgeList(f.capabilities.allowed, 'purple');
                const denied = badgeList(f.capabilities.denied, 'muted');
                const scopes = badgeList(f.scopes);

                const exposures = (f.exposures || []).map(e => `
                  <div class="detail-card" style="grid-column: 1 / -1;">
                    <h3>Exposure &mdash; ${e.entity}</h3>
                    <div class="detail-row"><span class="detail-key">Visible fields</span><span class="detail-val">${badgeList(e.visible_fields, 'teal')}</span></div>
                    <div class="detail-row"><span class="detail-key">Hidden fields</span><span class="detail-val">${badgeList(e.hidden_fields, 'muted')}</span></div>
                    <div class="detail-row"><span class="detail-key">Computed fields</span><span class="detail-val">${badgeList(e.computed_fields, 'purple')}</span></div>
                    <div class="detail-row"><span class="detail-key">Field aliases</span><span class="detail-val">${Object.keys(e.field_aliases || {}).length ? Object.entries(e.field_aliases).map(([k,v]) => `<span class="badge teal">${k} &rarr; ${v}</span>`).join(' ') : '<span class="badge muted">none</span>'}</span></div>
                  </div>`).join('');

                el.innerHTML = `
                  <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom: 20px;">
                    <div>
                      <h2 style="font-size:20px; font-weight:700;">${f.name}</h2>
                      <p style="color:var(--muted); font-size:13px; margin-top:4px;">${f.description || 'No description.'}</p>
                    </div>
                    <a href="/facera/openapi/${f.name}" class="btn btn-primary" style="flex:0; white-space:nowrap;">View OpenAPI &rarr;</a>
                  </div>
                  <div class="detail-grid">
                    <div class="detail-card">
                      <h3>General</h3>
                      <div class="detail-row"><span class="detail-key">Core</span><span class="detail-val"><span class="tbl-link" onclick="navigate('/cores/${f.core}')">${f.core}</span></span></div>
                      <div class="detail-row"><span class="detail-key">Format</span><span class="detail-val">${f.format || 'json'}</span></div>
                      <div class="detail-row"><span class="detail-key">Error verbosity</span><span class="detail-val">${f.error_verbosity || '—'}</span></div>
                      <div class="detail-row"><span class="detail-key">Audit logging</span><span class="detail-val">${f.audit_logging ? '<span class="badge teal">enabled</span>' : '<span class="badge muted">disabled</span>'}</span></div>
                      ${f.rate_limit ? `<div class="detail-row"><span class="detail-key">Rate limit</span><span class="detail-val">${f.rate_limit.requests} / ${f.rate_limit.per}</span></div>` : ''}
                    </div>
                    <div class="detail-card">
                      <h3>Capabilities</h3>
                      <div class="detail-row"><span class="detail-key">Allowed</span><span class="detail-val">${allowed}</span></div>
                      <div class="detail-row"><span class="detail-key">Denied</span><span class="detail-val">${denied}</span></div>
                      <div class="detail-row"><span class="detail-key">Scopes</span><span class="detail-val">${scopes}</span></div>
                    </div>
                    ${exposures}
                  </div>`;
              });

              // --- Cores list ---
              addRoute(new RegExp('^/cores$'), async (_, el) => {
                setNav('nav-cores');
                setBreadcrumb([{ href: '/cores', label: 'Cores' }]);
                loading(el);
                let cores;
                try { cores = await apiFetch('/cores'); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }

                const rows = cores.map(c => `<tr>
                  <td class="mono"><span class="tbl-link" onclick="navigate('/cores/${c.name}')">${c.name}</span></td>
                  <td>${c.entities.length}</td>
                  <td>${c.capabilities.length}</td>
                  <td>${c.invariants.length}</td>
                  <td><span class="tbl-link" onclick="navigate('/cores/${c.name}')">inspect &rarr;</span></td>
                </tr>`).join('');

                el.innerHTML = `
                  ${sectionHeader('Cores', cores.length)}
                  <div class="table-wrap"><table>
                    <thead><tr><th>Name</th><th>Entities</th><th>Capabilities</th><th>Invariants</th><th></th></tr></thead>
                    <tbody>${rows}</tbody>
                  </table></div>`;
              });

              // --- Core detail ---
              addRoute(new RegExp('^/cores/([^/]+)$'), async ([, name], el) => {
                setNav('nav-cores');
                setBreadcrumb([{ href: '/cores', label: 'Cores' }, { label: name }]);
                loading(el);
                let c;
                try { c = await apiFetch(`/cores/${name}`); } catch(e) { el.innerHTML = `<div class="empty">Error: ${e.message}</div>`; return; }

                const entities = c.entities.map(e => {
                  const attrs = e.attributes.map(a => {
                    const flags = [
                      a.required ? '<span class="badge teal">required</span>' : '',
                      a.immutable ? '<span class="badge purple">immutable</span>' : '',
                      a.enum_values ? `<span class="badge muted">enum</span>` : ''
                    ].filter(Boolean).join(' ');
                    return `<div class="attr-item"><span class="attr-name">${a.name}</span><span class="attr-type">${a.type || 'any'}</span>${flags}</div>`;
                  }).join('');
                  return `
                    <div class="detail-card" style="grid-column: 1 / -1;">
                      <h3>Entity &mdash; ${e.name}</h3>
                      <div class="attr-list">${attrs || '<span style="color:var(--muted);font-size:12px;">No attributes</span>'}</div>
                    </div>`;
                }).join('');

                const capabilities = c.capabilities.map(cap => {
                  const required = badgeList(cap.required_params, 'teal');
                  const optional = badgeList(cap.optional_params, 'muted');
                  const transitions = badgeList(cap.transitions_to, 'purple');
                  return `
                    <div class="cap-item">
                      <div class="cap-item-header">
                        <span class="cap-name">${cap.name}</span>
                        <span class="cap-type">${cap.type}</span>
                        ${cap.entity ? `<span class="badge teal">${cap.entity}</span>` : ''}
                      </div>
                      <div class="cap-meta">
                        <span style="font-size:11px; color:var(--muted);">Required:</span> ${required}
                        &nbsp;<span style="font-size:11px; color:var(--muted);">Optional:</span> ${optional}
                        ${cap.transitions_to && cap.transitions_to.length ? `&nbsp;<span style="font-size:11px; color:var(--muted);">Transitions:</span> ${transitions}` : ''}
                      </div>
                    </div>`;
                }).join('');

                const invariants = c.invariants.map(inv => `
                  <div class="detail-row">
                    <span class="detail-key mono">${inv.name}</span>
                    <span class="detail-val">${inv.description || '—'}</span>
                  </div>`).join('');

                el.innerHTML = `
                  <h2 style="font-size:20px; font-weight:700; margin-bottom:20px;">${c.name}</h2>
                  <div class="detail-grid">
                    ${entities}
                    <div class="detail-card" style="grid-column: 1 / -1;">
                      <h3>Capabilities (${c.capabilities.length})</h3>
                      <div class="cap-list">${capabilities || '<span style="color:var(--muted);font-size:12px;">No capabilities</span>'}</div>
                    </div>
                    ${c.invariants.length ? `
                    <div class="detail-card" style="grid-column: 1 / -1;">
                      <h3>Invariants (${c.invariants.length})</h3>
                      ${invariants}
                    </div>` : ''}
                  </div>`;
              });

              // --- Boot ---
              (function boot() {
                const full = location.pathname;
                const base = '/facera';
                let path = full.startsWith(base) ? full.slice(base.length) : full;
                if (!path || path === '') path = '/';
                navigate(path, false);
              })();
            </script>
          </body>
          </html>
        HTML

        html
      end
    end

    get '/' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    # Catch-all for client-side routes so deep links / reloads work
    get '/facets' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/facets/:name' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/cores' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/cores/:name' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/apis' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/apis/:name' do
      header 'Content-Type', 'text/html; charset=utf-8'
      spa_shell
    end

    get '/openapi/:name' do
      header 'Content-Type', 'text/html; charset=utf-8'
      base = Facera.configuration.base_path
      name = params[:name]
      swagger_ui("#{name} — OpenAPI", "#{base}/facera/openapi/#{name}")
    end
  end
end
