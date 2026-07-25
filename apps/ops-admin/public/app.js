const reportTypeLabels = {
  accident: "事故",
  construction: "施工",
  jam: "拥堵",
  closure: "封路",
  illegal_parking: "违停",
  pothole: "坑洼",
  checkpoint: "临检",
};

const statusLabels = {
  pending: "待审",
  approved: "通过",
  rejected: "驳回",
};

const state = {
  baseUrl: normalizeBaseUrl(
    localStorage.getItem("reportServiceBaseUrl") ||
      window.__OPS_ADMIN_CONFIG__?.reportServiceBaseUrl ||
      "http://localhost:3001",
  ),
  status: "",
  reports: [],
  loading: false,
};

const elements = {
  approvedCount: document.querySelector("#approved-count"),
  baseUrlInput: document.querySelector("#base-url-input"),
  emptyState: document.querySelector("#empty-state"),
  pendingCount: document.querySelector("#pending-count"),
  refreshButton: document.querySelector("#refresh-button"),
  rejectedCount: document.querySelector("#rejected-count"),
  reportsBody: document.querySelector("#reports-body"),
  statusMessage: document.querySelector("#status-message"),
  statusTabs: Array.from(document.querySelectorAll(".status-tab")),
};

elements.baseUrlInput.value = state.baseUrl;
elements.refreshButton.addEventListener("click", () => {
  void loadReports();
});
elements.baseUrlInput.addEventListener("change", () => {
  state.baseUrl = normalizeBaseUrl(elements.baseUrlInput.value);
  elements.baseUrlInput.value = state.baseUrl;
  localStorage.setItem("reportServiceBaseUrl", state.baseUrl);
  void loadReports();
});

for (const tab of elements.statusTabs) {
  tab.addEventListener("click", () => {
    state.status = tab.dataset.status || "";
    renderTabs();
    void loadReports();
  });
}

void loadReports();

async function loadReports() {
  setLoading(true);

  try {
    const url = new URL("/reports", `${state.baseUrl}/`);

    if (state.status) {
      url.searchParams.set("status", state.status);
    }

    const response = await fetch(url);
    const payload = await readJson(response);

    if (!response.ok) {
      throw new Error(payload.error?.message || `HTTP ${response.status}`);
    }

    state.reports = Array.isArray(payload.reports) ? payload.reports : [];
    renderReports();
    setMessage(`${state.reports.length} 条记录`);
  } catch (error) {
    state.reports = [];
    renderReports();
    setMessage(error instanceof Error ? error.message : "加载失败", true);
  } finally {
    setLoading(false);
  }
}

async function reviewReport(id, status) {
  setLoading(true);

  try {
    const response = await fetch(new URL(`/reports/${encodeURIComponent(id)}`, `${state.baseUrl}/`), {
      body: JSON.stringify({ status }),
      headers: {
        "content-type": "application/json",
      },
      method: "PATCH",
    });
    const payload = await readJson(response);

    if (!response.ok) {
      throw new Error(payload.error?.message || `HTTP ${response.status}`);
    }

    setMessage(`已${statusLabels[status]} ${id}`);
    await loadReports();
  } catch (error) {
    setMessage(error instanceof Error ? error.message : "审核失败", true);
    setLoading(false);
  }
}

async function readJson(response) {
  try {
    return await response.json();
  } catch {
    return {};
  }
}

function renderReports() {
  elements.reportsBody.textContent = "";
  elements.emptyState.hidden = state.reports.length > 0;

  for (const report of state.reports) {
    elements.reportsBody.append(createReportRow(report));
  }

  renderCounts();
}

function createReportRow(report) {
  const row = document.createElement("tr");
  row.append(
    createCell(reportTypeLabels[report.type] || report.type || "-"),
    createCell(formatLocation(report.location), "location"),
    createCell(report.description || report.imageRef || "-", "description"),
    createCell(report.anonymous ? "是" : "否"),
    createStatusCell(report.status),
    createCell(formatTime(report.createdAt), "muted"),
    createActionsCell(report),
  );
  return row;
}

function createCell(text, className) {
  const cell = document.createElement("td");
  cell.textContent = text;

  if (className) {
    cell.className = className;
  }

  return cell;
}

function createStatusCell(status) {
  const cell = document.createElement("td");
  const badge = document.createElement("span");
  badge.className = `badge ${status || "pending"}`;
  badge.textContent = statusLabels[status] || status || "-";
  cell.append(badge);
  return cell;
}

function createActionsCell(report) {
  const cell = document.createElement("td");
  const actions = document.createElement("div");
  actions.className = "actions";

  if (report.status === "pending") {
    actions.append(
      createReviewButton("通过", "approve", () => reviewReport(report.id, "approved")),
      createReviewButton("驳回", "reject", () => reviewReport(report.id, "rejected")),
    );
  } else {
    const text = document.createElement("span");
    text.className = "muted";
    text.textContent = "已处理";
    actions.append(text);
  }

  cell.append(actions);
  return cell;
}

function createReviewButton(label, className, onClick) {
  const button = document.createElement("button");
  button.className = `action-button ${className}`;
  button.type = "button";
  button.textContent = label;
  button.addEventListener("click", () => {
    void onClick();
  });
  return button;
}

function renderCounts() {
  const counts = {
    approved: 0,
    pending: 0,
    rejected: 0,
  };

  for (const report of state.reports) {
    if (Object.hasOwn(counts, report.status)) {
      counts[report.status] += 1;
    }
  }

  elements.approvedCount.textContent = String(counts.approved);
  elements.pendingCount.textContent = String(counts.pending);
  elements.rejectedCount.textContent = String(counts.rejected);
}

function renderTabs() {
  for (const tab of elements.statusTabs) {
    tab.classList.toggle("is-active", (tab.dataset.status || "") === state.status);
  }
}

function setLoading(loading) {
  state.loading = loading;
  elements.refreshButton.disabled = loading;
  elements.refreshButton.textContent = loading ? "加载中" : "刷新";
}

function setMessage(message, isError = false) {
  elements.statusMessage.textContent = message;
  elements.statusMessage.classList.toggle("is-error", isError);
}

function normalizeBaseUrl(value) {
  try {
    return new URL(value).toString().replace(/\/$/, "");
  } catch {
    return "http://localhost:3001";
  }
}

function formatLocation(location) {
  if (!Array.isArray(location) || location.length !== 2) {
    return "-";
  }

  return `${Number(location[0]).toFixed(5)}, ${Number(location[1]).toFixed(5)}`;
}

function formatTime(value) {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("zh-CN", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(date);
}
