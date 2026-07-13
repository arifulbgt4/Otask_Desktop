import { useMemo, useState } from "react";
import {
  navigationItems,
  routeById,
  type DesktopRoute,
  type NavigationItem,
} from "./navigation";

const statusCards = [
  { label: "Trusted devices", value: "3", detail: "All healthy", tone: "good" },
  { label: "Queued runs", value: "2", detail: "Next in 12 min", tone: "info" },
  {
    label: "Needs approval",
    value: "1",
    detail: "Review required",
    tone: "warn",
  },
];

const groupLabels: Record<NavigationItem["group"], string> = {
  operate: "Operate",
  observe: "Observe",
  configure: "Configure",
};

function Dashboard({
  onNavigate,
}: {
  onNavigate: (route: DesktopRoute) => void;
}) {
  return (
    <div className="screen-stack">
      <section className="hero-panel">
        <div>
          <p className="eyebrow">LOCAL CONTROL PLANE</p>
          <h2>Good morning, Ariful.</h2>
          <p className="muted">
            Your trusted devices and scheduled workflows are ready for review.
          </p>
        </div>
        <button
          className="primary-button"
          onClick={() => onNavigate("workflows")}
        >
          Create workflow
        </button>
      </section>
      <section className="card-grid" aria-label="System status">
        {statusCards.map((card) => (
          <article className={`status-card ${card.tone}`} key={card.label}>
            <p className="muted">{card.label}</p>
            <strong>{card.value}</strong>
            <span>{card.detail}</span>
          </article>
        ))}
      </section>
      <section className="content-grid">
        <article className="panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">NEXT ACTION</p>
              <h3>Review a terminal approval</h3>
            </div>
            <span className="risk-badge">Elevated</span>
          </div>
          <p className="muted">
            A read-only terminal session is waiting for your explicit approval
            before it can connect to the development device.
          </p>
          <button
            className="secondary-button"
            onClick={() => onNavigate("approvals")}
          >
            Open approvals
          </button>
        </article>
        <article className="panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">RECENT ACTIVITY</p>
              <h3>Execution evidence</h3>
            </div>
            <button
              className="text-button"
              onClick={() => onNavigate("reports")}
            >
              View all
            </button>
          </div>
          <ul className="activity-list">
            <li>
              <span className="dot good-dot" />
              Daily backup completed · 8 min ago
            </li>
            <li>
              <span className="dot info-dot" />
              Device sync resumed · 24 min ago
            </li>
            <li>
              <span className="dot warn-dot" />
              Approval requested · 31 min ago
            </li>
          </ul>
        </article>
      </section>
    </div>
  );
}

function GenericScreen({ item }: { item: NavigationItem }) {
  return (
    <div className="screen-stack">
      <section className="panel page-intro">
        <p className="eyebrow">{groupLabels[item.group].toUpperCase()}</p>
        <h2>{item.label}</h2>
        <p className="muted">
          {item.description}. This screen is ready for the next vertical slice.
        </p>
      </section>
      <section className="empty-state panel">
        <div className="empty-icon" aria-hidden="true">
          ○
        </div>
        <h3>Nothing needs attention here</h3>
        <p className="muted">
          The trusted service will populate this view when it is connected.
        </p>
      </section>
    </div>
  );
}

export default function App() {
  const [route, setRoute] = useState<DesktopRoute>("dashboard");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const current = useMemo(() => routeById[route], [route]);

  return (
    <div className="app-shell" data-shell="tauri-v2">
      <aside className={`sidebar ${sidebarOpen ? "open" : "collapsed"}`}>
        <div className="brand-row">
          <div className="brand-mark" aria-hidden="true">
            O
          </div>
          {sidebarOpen && (
            <div>
              <strong>OTask</strong>
              <span>Desktop control plane</span>
            </div>
          )}
        </div>
        <nav aria-label="Primary navigation">
          {(["operate", "observe", "configure"] as const).map((group) => (
            <div className="nav-group" key={group}>
              {sidebarOpen && <p>{groupLabels[group]}</p>}
              {navigationItems
                .filter((item) => item.group === group)
                .map((item) => (
                  <button
                    className={`nav-item ${route === item.id ? "active" : ""}`}
                    key={item.id}
                    onClick={() => setRoute(item.id)}
                    aria-current={route === item.id ? "page" : undefined}
                    title={sidebarOpen ? undefined : item.label}
                  >
                    <span className="nav-glyph" aria-hidden="true">
                      {item.label.slice(0, 1)}
                    </span>
                    {sidebarOpen && <span>{item.label}</span>}
                  </button>
                ))}
            </div>
          ))}
        </nav>
        <div className="sidebar-footer">
          <span className="connection-dot" />
          {sidebarOpen && <span>Service connected</span>}
        </div>
      </aside>
      <div className="main-column">
        <header className="topbar">
          <button
            className="icon-button"
            onClick={() => setSidebarOpen((open) => !open)}
            aria-label="Toggle navigation"
          >
            ☰
          </button>
          <div className="breadcrumbs">
            <span>OTask</span>
            <span aria-hidden="true">/</span>
            <strong>{current.label}</strong>
          </div>
          <div className="topbar-actions">
            <span className="environment-badge">LOCAL</span>
            <button className="avatar-button" aria-label="Open account menu">
              AI
            </button>
          </div>
        </header>
        <main className="main-content">
          {route === "dashboard" ? (
            <Dashboard onNavigate={setRoute} />
          ) : (
            <GenericScreen item={current} />
          )}
        </main>
      </div>
    </div>
  );
}
