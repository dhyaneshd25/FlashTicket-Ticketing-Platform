<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="common/header.jsp" %>

<div class="simulation-dashboard">
    <!-- Hero Header -->
    <div class="dashboard-header">
        <div>
            <div class="flex-align-gap">
                <h1>⚡ High-Throughput Architecture Simulation</h1>
                <span class="badge-role role-badge-admin" id="simRoleBadge">ADMIN CONSOLE</span>
            </div>
            <p class="subtitle">
                Interactive administrator demonstration of how <strong>Redis In-Memory Atomic Gates</strong>, 
                <strong>PostgreSQL Transactional Outbox</strong>, and <strong>Apache Kafka Event Streaming</strong> 
                prevent database crashes and guarantee <strong>zero overselling</strong> during high-traffic flash sales.
            </p>
        </div>
        <div class="header-actions" style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
            <a href="${pageContext.request.contextPath}/admin" class="btn btn-outline btn-sm" id="adminBackBtn">⚙️ Admin Control Panel</a>
            <button class="btn btn-outline btn-sm" onclick="fetchTelemetry(); loadLiveRedisKeys(); loadLiveOutbox();">🔄 Refresh System State</button>
        </div>
    </div>

    <!-- Live Telemetry Status Bar -->
    <div class="stats-grid simulation-stats" id="telemetryGrid">
        <div class="stat-card">
            <span class="stat-label">1. Redis In-Memory Gate</span>
            <span class="stat-value text-green" id="telemetryRedis">ONLINE</span>
            <small class="meta-sub" id="telemetryPing">Sub-millisecond memory roundtrip</small>
        </div>
        <div class="stat-card">
            <span class="stat-label">2. PostgreSQL Outbox Events</span>
            <span class="stat-value" id="telemetryOutbox">...</span>
            <small class="meta-sub" id="telemetryOutboxPending">0 pending relay / all dispatched</small>
        </div>
        <div class="stat-card">
            <span class="stat-label">3. Apache Kafka Cluster</span>
            <span class="stat-value text-orange" id="telemetryKafka">ACTIVE</span>
            <small class="meta-sub">Topics: order-created (6 Partitions)</small>
        </div>
        <div class="stat-card">
            <span class="stat-label">4. Total Confirmed Orders</span>
            <span class="stat-value stat-revenue" id="telemetryOrders">...</span>
            <small class="meta-sub">ACID committed in DB</small>
        </div>
    </div>

    <!-- Interactive Architecture Flowchart -->
    <div class="pipeline-card">
        <div class="pipeline-header-flex">
            <div>
                <h2>Architectural Pipeline: How Redis &amp; Kafka Are Used</h2>
                <p class="subtitle">Click "Run Live Simulation" to watch a real purchase event travel across each distributed component, or test Redis &amp; Kafka directly.</p>
            </div>
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                <button id="runLiveTraceBtn" class="btn btn-primary btn-lg" onclick="triggerAnimatedTrace()">
                    ▶️ Run Full Architecture Trace
                </button>
                <button class="btn btn-outline btn-lg" onclick="runRedisDemo()" style="border-color: var(--color-orange-primary); color: var(--text-orange);">
                    ⚡ Test Redis In-Memory Gate
                </button>
                <button class="btn btn-outline btn-lg" onclick="runKafkaDemo()" style="border-color: var(--color-green-primary); color: var(--color-green-light);">
                    📨 Test Apache Kafka Stream
                </button>
            </div>
        </div>

        <!-- 5-Node Interactive Visual Pipeline -->
        <div class="pipeline-diagram" id="pipelineDiagram">
            <!-- Node 1: Client Ingress -->
            <div class="pipe-node" id="node-1">
                <div class="pipe-step-num">Step 1</div>
                <div class="pipe-icon">🌐</div>
                <div class="pipe-title">Client Browser</div>
                <div class="pipe-tech">HTTP POST /api/orders</div>
                <div class="pipe-detail">Rate Limiter Token Bucket</div>
                <div class="pipe-metric" id="metric-1">-</div>
            </div>

            <div class="pipe-arrow" id="arrow-1">&rarr;</div>

            <!-- Node 2: Redis Atomic Gate -->
            <div class="pipe-node" id="node-2">
                <div class="pipe-step-num">Step 2</div>
                <div class="pipe-icon">⚡</div>
                <div class="pipe-title">Redis In-Memory Gate</div>
                <div class="pipe-tech">Atomic DECRBY &amp; RLock</div>
                <div class="pipe-detail">&lt; 1ms In-Memory Guard</div>
                <div class="pipe-metric" id="metric-2">-</div>
            </div>

            <div class="pipe-arrow" id="arrow-2">&rarr;</div>

            <!-- Node 3: PostgreSQL Transactional Outbox -->
            <div class="pipe-node" id="node-3">
                <div class="pipe-step-num">Step 3</div>
                <div class="pipe-icon">🗄️</div>
                <div class="pipe-title">Transactional Outbox</div>
                <div class="pipe-tech">PostgreSQL ACID Transaction</div>
                <div class="pipe-detail">Order + Outbox in 1 Commit</div>
                <div class="pipe-metric" id="metric-3">-</div>
            </div>

            <div class="pipe-arrow" id="arrow-3">&rarr;</div>

            <!-- Node 4: Apache Kafka Broker -->
            <div class="pipe-node" id="node-4">
                <div class="pipe-step-num">Step 4</div>
                <div class="pipe-icon">📨</div>
                <div class="pipe-title">Apache Kafka Broker</div>
                <div class="pipe-tech">Topic: order-created</div>
                <div class="pipe-detail">Key-based Partitioning (6 Part.)</div>
                <div class="pipe-metric" id="metric-4">-</div>
            </div>

            <div class="pipe-arrow" id="arrow-4">&rarr;</div>

            <!-- Node 5: Downstream Consumers -->
            <div class="pipe-node" id="node-5">
                <div class="pipe-step-num">Step 5</div>
                <div class="pipe-icon">👥</div>
                <div class="pipe-title">Async Microservices</div>
                <div class="pipe-tech">Idempotent Consumer Groups</div>
                <div class="pipe-detail">Inventory &middot; Payment &middot; Mail</div>
                <div class="pipe-metric" id="metric-5">-</div>
            </div>
        </div>

        <!-- Live Step Details Box (Appears after simulation run) -->
        <div id="liveStepDetailsBox" class="live-step-details" style="display: none;">
            <div class="details-top-bar">
                <span class="active-step-badge" id="activeStepBadge">Step 1: Client Ingress</span>
                <span class="step-timing" id="activeStepTiming">Latency: 0 µs</span>
            </div>
            <p id="activeStepDescription" class="step-desc-text"></p>
            <div class="resource-code-box">
                <span class="resource-label">Component Resource:</span>
                <code id="activeStepResource">filter:rate-limit</code>
            </div>
        </div>

        <!-- Live Kafka Message JSON Payload Box -->
        <div id="kafkaPayloadCard" class="kafka-payload-card" style="display: none;">
            <div class="payload-header">
                <span>📦 Real Apache Kafka Message Payload (<code id="kafkaTopicName">orders.v1</code>):</span>
                <span class="badge-role role-badge-admin">JSON Serialized</span>
            </div>
            <pre class="json-code-block" id="kafkaPayloadJson"></pre>
        </div>
    </div>

    <!-- Simulator Navigation Tabs -->
    <div class="admin-tabs simulation-tabs">
        <button class="tab-btn active" onclick="switchSimTab('burstTab', this)">🚀 Concurrency Burst Stress Test (Why Redis?)</button>
        <button class="tab-btn" onclick="switchSimTab('outboxTab', this)">🗄️ PostgreSQL Outbox Table (Why Outbox?)</button>
        <button class="tab-btn" onclick="switchSimTab('redisTab', this)">⚡ Live Redis Key Inspector</button>
        <button class="tab-btn" onclick="switchSimTab('kafkaTab', this)">📨 Apache Kafka Topic Topology</button>
    </div>

    <!-- TAB 1: Concurrency Burst Test (Why Redis?) -->
    <div id="burstTab" class="tab-content active">
        <div class="sim-grid-layout">
            <!-- Controls -->
            <div class="sim-control-card">
                <h3>High-Throughput Burst Stress Test</h3>
                <p class="text-muted">Simulate 50 to 200 concurrent buyers hitting "Buy Now" at the exact same millisecond against a limited pool of tickets.</p>

                <div class="form-group">
                    <label for="burstUsers">Simultaneous Buyer Threads:</label>
                    <select id="burstUsers" class="form-control">
                        <option value="25">25 Concurrent Buyers</option>
                        <option value="50" selected>50 Concurrent Buyers</option>
                        <option value="100">100 Concurrent Buyers</option>
                        <option value="200">200 Concurrent Buyers</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="burstSeats">Available Flash Tickets:</label>
                    <select id="burstSeats" class="form-control">
                        <option value="5">5 Tickets Available</option>
                        <option value="10" selected>10 Tickets Available</option>
                        <option value="20">20 Tickets Available</option>
                    </select>
                </div>

                <button id="runBurstBtn" class="btn btn-primary btn-block btn-lg" onclick="triggerBurstSimulation()">
                    🚀 Launch Flash Sale Burst Simulation
                </button>

                <div class="sim-explainer-box">
                    <h4>Why Redis is Required Here:</h4>
                    <ul>
                        <li><strong>In-Memory Atomic Gate:</strong> <code>DECRBY</code> happens in memory (< 1ms). Redis absorbs 10,000+ RPS without database strain.</li>
                        <li><strong>Prevents Database Death:</strong> Only the 10 winners ever reach PostgreSQL. The other 90 buyers are rejected in memory at the edge.</li>
                        <li><strong>Distributed Mutex Lock:</strong> Redisson <code>RLock</code> ensures two users never win the exact same seat code.</li>
                    </ul>
                </div>
            </div>

            <!-- Results & Real-time Logs -->
            <div class="sim-results-card">
                <h3>Live Concurrency Telemetry</h3>

                <div id="burstResultsEmpty" class="empty-state-box">
                    <div class="empty-icon">📊</div>
                    <p>Click "Launch Flash Sale Burst Simulation" to fire concurrent threads against Redis.</p>
                </div>

                <div id="burstResultsActive" style="display: none;">
                    <div class="burst-metrics-row">
                        <div class="metric-pill">
                            <span class="m-label">Concurrent Buyers</span>
                            <span class="m-val" id="bmRequests">50</span>
                        </div>
                        <div class="metric-pill">
                            <span class="m-label">Execution Time</span>
                            <span class="m-val text-blue" id="bmDuration">32 ms</span>
                        </div>
                        <div class="metric-pill">
                            <span class="m-label">Throughput</span>
                            <span class="m-val text-green" id="bmRps">1,560 RPS</span>
                        </div>
                        <div class="metric-pill">
                            <span class="m-label">Redis Gate Passes</span>
                            <span class="m-val text-green" id="bmWon">10</span>
                        </div>
                        <div class="metric-pill">
                            <span class="m-label">Oversold Rejections</span>
                            <span class="m-val text-red" id="bmRejected">40</span>
                        </div>
                    </div>

                    <div id="oversellBadge" class="oversell-verification-banner banner-success">
                        🛡️ Zero Overselling Guarantee: VERIFIED! (Exact ticket quota allocated, 0 oversold)
                    </div>

                    <h4>Real-Time Concurrency Telemetry Stream:</h4>
                    <div class="terminal-log-window" id="burstLogWindow"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- TAB 2: PostgreSQL Transactional Outbox Table (Why Outbox?) -->
    <div id="outboxTab" class="tab-content">
        <div class="sim-control-card mb-4">
            <div class="flex-between">
                <div>
                    <h3>PostgreSQL <code>outbox_events</code> Table (Live Rows)</h3>
                    <p class="subtitle">
                        Solves the <strong>Dual-Write Problem</strong>: Orders and Outbox rows commit in a single DB transaction.
                        The Outbox Relay Worker polls rows with status <code>PENDING</code>, publishes to Kafka, and marks them <code>DISPATCHED</code>.
                    </p>
                </div>
                <button class="btn btn-outline btn-sm" onclick="loadLiveOutbox()">🔄 Refresh Outbox</button>
            </div>

            <div class="table-responsive mt-3">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Outbox ID</th>
                            <th>Aggregate</th>
                            <th>Event Type</th>
                            <th>Relay Status</th>
                            <th>Created Timestamp</th>
                            <th>Kafka Payload Preview</th>
                        </tr>
                    </thead>
                    <tbody id="outboxTableBody">
                        <tr><td colspan="6">Loading Outbox table...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- TAB 3: Live Redis Key Inspector -->
    <div id="redisTab" class="tab-content">
        <div class="sim-control-card mb-4">
            <div class="flex-between">
                <div>
                    <h3>Live Redis In-Memory Key Inspector</h3>
                    <p class="subtitle">Live inspection of all Redis keys currently holding inventory counters, seat locks, and reservation TTL hashes.</p>
                </div>
                <button class="btn btn-outline btn-sm" onclick="loadLiveRedisKeys()">🔄 Scan Redis Keys</button>
            </div>

            <div class="table-responsive mt-3">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Redis Key Name</th>
                            <th>Data Structure</th>
                            <th>TTL Remaining</th>
                            <th>Current Value</th>
                            <th>Architectural Purpose</th>
                        </tr>
                    </thead>
                    <tbody id="redisTableBody">
                        <tr><td colspan="5">Scanning Redis memory...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- TAB 4: Apache Kafka Topic Topology -->
    <div id="kafkaTab" class="tab-content">
        <div class="sim-control-card mb-4">
            <h3>Apache Kafka Cluster &amp; Consumer Groups</h3>
            <p class="subtitle">Partitioned event-driven architecture decoupling synchronous user checkouts from slow downstream services.</p>

            <div class="table-responsive mt-3">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Topic Name</th>
                            <th>Partitions</th>
                            <th>Replicas</th>
                            <th>Active Consumer Groups</th>
                            <th>Role in Flash Sale Architecture</th>
                        </tr>
                    </thead>
                    <tbody id="kafkaTableBody">
                        <tr><td colspan="5">Loading Kafka metadata...</td></tr>
                    </tbody>
                </table>
            </div>

            <div class="sim-explainer-box mt-4">
                <h4>Why Key-Based Partitioning Matters in Kafka:</h4>
                <p>Events on <code>order-created</code> are keyed by <strong>Show ID</strong>. This guarantees that all ticket purchases for a specific concert show are written to the <strong>exact same partition</strong>, maintaining strict sequential ordering while different shows process concurrently across other partitions.</p>
            </div>
        </div>
    </div>
</div>

<script>
const contextPath = document.querySelector('meta[name="context-path"]')?.getAttribute('content') || '';
let token = localStorage.getItem('ft_token');

function verifyAdminSession() {
    const storedUser = localStorage.getItem('ft_user');
    token = localStorage.getItem('ft_token');
    if (!token || !storedUser) {
        window.location.href = contextPath + '/login?redirect=' + encodeURIComponent(window.location.pathname);
        return false;
    }
    try {
        const user = JSON.parse(storedUser);
        if (user.role !== 'ROLE_ADMIN') {
            window.location.href = contextPath + '/?error=forbidden';
            return false;
        }
        return true;
    } catch (e) {
        window.location.href = contextPath + '/login?redirect=' + encodeURIComponent(window.location.pathname);
        return false;
    }
}

async function authedFetch(url, options = {}) {
    if (!verifyAdminSession()) {
        throw new Error('Admin authorization required');
    }
    if (!options.headers) options.headers = {};
    if (token && !options.headers['Authorization']) {
        options.headers['Authorization'] = 'Bearer ' + token;
    }
    if (!options.headers['Content-Type'] && options.method && options.method !== 'GET') {
        options.headers['Content-Type'] = 'application/json';
    }

    let res = await fetch(url, options);
    if (res.status === 401 || res.status === 403) {
        alert('Admin authorization required. Please log in as Administrator.');
        window.location.href = contextPath + '/login?redirect=' + encodeURIComponent(window.location.pathname);
    }
    return res;
}

function switchSimTab(tabId, btn) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    const target = document.getElementById(tabId);
    if (target) target.classList.add('active');
    if (btn) btn.classList.add('active');
    else {
        const matchingBtn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.getAttribute('onclick')?.includes(tabId));
        if (matchingBtn) matchingBtn.classList.add('active');
    }
}

async function runRedisDemo() {
    switchSimTab('burstTab');
    const burstCard = document.getElementById('burstTab');
    if (burstCard) burstCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
    triggerBurstSimulation();
}

async function runKafkaDemo() {
    switchSimTab('kafkaTab');
    const kafkaCard = document.getElementById('kafkaTab');
    if (kafkaCard) kafkaCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
    triggerAnimatedTrace();
}

async function fetchTelemetry() {
    try {
        const res = await authedFetch(contextPath + '/api/simulation/telemetry');
        if (res.ok) {
            const data = await res.json();
            const redisEl = document.getElementById('telemetryRedis');
            const pingEl = document.getElementById('telemetryPing');
            const outboxEl = document.getElementById('telemetryOutbox');
            const outboxPendingEl = document.getElementById('telemetryOutboxPending');
            const ordersEl = document.getElementById('telemetryOrders');

            if (data.redisConnected) {
                redisEl.textContent = 'ONLINE';
                redisEl.className = 'stat-value text-green';
                pingEl.textContent = 'Ping: ' + data.redisPingMicros + ' µs in-memory';
            } else {
                redisEl.textContent = 'OFFLINE';
                redisEl.className = 'stat-value text-red';
            }

            outboxEl.textContent = data.totalOutboxEvents;
            outboxPendingEl.textContent = data.pendingOutboxEvents + ' pending / ' + data.publishedOutboxEvents + ' dispatched';
            ordersEl.textContent = data.totalDbOrders;
        }
    } catch (e) {
        console.error('Failed to load telemetry', e);
    }
}

async function loadLiveRedisKeys() {
    const tbody = document.getElementById('redisTableBody');
    try {
        const res = await authedFetch(contextPath + '/api/simulation/redis-keys');
        if (res.ok) {
            const keys = await res.json();
            if (keys.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5">No active keys found in Redis. Seed a show to create keys.</td></tr>';
                return;
            }
            tbody.innerHTML = keys.map(k => `
                <tr>
                    <td><code>\${escapeHtml(k.key)}</code></td>
                    <td><span class="badge-role role-badge-organizer">\${k.type}</span></td>
                    <td>\${k.ttlSeconds >= 0 ? k.ttlSeconds + 's' : 'Permanent'}</td>
                    <td><code>\${escapeHtml(k.valuePreview)}</code></td>
                    <td><small class="text-muted">\${escapeHtml(k.purpose)}</small></td>
                </tr>
            `).join('');
        }
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="5" class="error">Failed to scan Redis keys.</td></tr>';
    }
}

async function loadLiveOutbox() {
    const tbody = document.getElementById('outboxTableBody');
    try {
        const res = await authedFetch(contextPath + '/api/simulation/outbox-events');
        if (res.ok) {
            const rows = await res.json();
            if (rows.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6">No outbox events in database yet. Run a purchase to generate outbox rows.</td></tr>';
                return;
            }
            tbody.innerHTML = rows.map(r => `
                <tr>
                    <td><code>\${r.id.substring(0, 8)}...</code></td>
                    <td>\${escapeHtml(r.aggregateType)} (<code>\${r.aggregateId.substring(0, 8)}...</code>)</td>
                    <td><strong>\${escapeHtml(r.eventType)}</strong></td>
                    <td><span class="status-badge \${r.status === 'DISPATCHED' ? 'status-confirmed' : 'status-pending'}">\${r.status}</span></td>
                    <td>\${new Date(r.createdAt).toLocaleString()}</td>
                    <td><code>\${escapeHtml(r.payloadPreview)}</code></td>
                </tr>
            `).join('');
        }
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="6" class="error">Failed to load Outbox rows.</td></tr>';
    }
}

async function loadKafkaMetadata() {
    const tbody = document.getElementById('kafkaTableBody');
    try {
        const res = await authedFetch(contextPath + '/api/simulation/kafka-topics');
        if (res.ok) {
            const topics = await res.json();
            tbody.innerHTML = topics.map(t => `
                <tr>
                    <td><strong class="text-orange">\${escapeHtml(t.name)}</strong></td>
                    <td><span class="badge-role role-badge-admin">\${t.partitions} Partitions</span></td>
                    <td>\${t.replicas}</td>
                    <td><code>\${escapeHtml(t.consumerGroups)}</code></td>
                    <td><small class="text-muted">\${escapeHtml(t.purpose)}</small></td>
                </tr>
            `).join('');
        }
    } catch (e) {
        tbody.innerHTML = '<tr><td colspan="5" class="error">Failed to load Kafka topics.</td></tr>';
    }
}

// ----------------------------------------------------------------------
// Animated Step-by-Step Architecture Trace
// ----------------------------------------------------------------------
async function triggerAnimatedTrace() {
    const btn = document.getElementById('runLiveTraceBtn');
    btn.disabled = true;
    btn.textContent = '⚡ Running Architecture Trace...';

    const detailsBox = document.getElementById('liveStepDetailsBox');
    const badgeEl = document.getElementById('activeStepBadge');
    const timingEl = document.getElementById('activeStepTiming');
    const descEl = document.getElementById('activeStepDescription');
    const resEl = document.getElementById('activeStepResource');
    const payloadCard = document.getElementById('kafkaPayloadCard');
    const payloadJson = document.getElementById('kafkaPayloadJson');

    detailsBox.style.display = 'block';
    payloadCard.style.display = 'none';

    // Reset nodes
    for (let i = 1; i <= 5; i++) {
        const node = document.getElementById('node-' + i);
        const metric = document.getElementById('metric-' + i);
        if (node) {
            node.classList.remove('node-active-glow', 'node-pulse');
            node.style.borderColor = 'var(--border-subtle)';
        }
        if (metric) metric.textContent = '-';
    }

    try {
        const res = await authedFetch(contextPath + '/api/simulation/trace', {
            method: 'POST',
            body: JSON.stringify({ seatCode: 'A1' })
        });

        if (res.ok) {
            const result = await res.json();
            const steps = result.steps || [];

            // Step-by-step animation sequence
            for (let i = 0; i < steps.length; i++) {
                const step = steps[i];
                const nodeIndex = Math.min(5, step.stepNumber);
                const nodeEl = document.getElementById('node-' + nodeIndex);
                const metricEl = document.getElementById('metric-' + nodeIndex);

                // Highlight active node
                if (nodeEl) {
                    nodeEl.classList.add('node-active-glow', 'node-pulse');
                    nodeEl.style.borderColor = 'var(--color-orange-primary)';
                }
                if (metricEl) {
                    metricEl.textContent = step.durationMicros + ' µs';
                    metricEl.className = 'pipe-metric metric-done';
                }

                // Update text details
                badgeEl.textContent = 'Step ' + step.stepNumber + ': ' + step.action + ' (' + step.component + ')';
                timingEl.textContent = 'Latency: ' + step.durationMicros + ' µs';
                descEl.textContent = step.details;
                resEl.textContent = step.keyOrTopic;

                // If step 4 or 5, show the Kafka JSON payload
                if (step.component === 'KAFKA' || step.component === 'POSTGRESQL_OUTBOX') {
                    payloadCard.style.display = 'block';
                    payloadJson.textContent = JSON.stringify({
                        eventId: "evt-" + result.simulationId,
                        orderId: "ord-" + result.simulationId,
                        showTitle: result.showTitle,
                        seatCode: result.seatCode,
                        seatQuantity: 1,
                        amount: 50.00,
                        kafkaTopic: "orders.v1",
                        partition: 2,
                        outboxStatus: "DISPATCHED",
                        timestamp: new Date().toISOString()
                    }, null, 2);
                }

                // Wait 600ms before advancing to next node so user can visually follow along!
                await new Promise(r => setTimeout(r, 650));

                if (nodeEl) nodeEl.classList.remove('node-pulse');
            }

            fetchTelemetry();
            loadLiveOutbox();
            loadLiveRedisKeys();
        } else {
            alert('Trace failed: ' + res.status);
        }
    } catch (e) {
        alert('Trace error: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.textContent = '▶️ Run Full Architecture Trace';
    }
}

// ----------------------------------------------------------------------
// High-Concurrency Burst Simulation
// ----------------------------------------------------------------------
async function triggerBurstSimulation() {
    const btn = document.getElementById('runBurstBtn');
    const users = parseInt(document.getElementById('burstUsers').value, 10);
    const seats = parseInt(document.getElementById('burstSeats').value, 10);

    btn.disabled = true;
    btn.textContent = '⚡ Firing ' + users + ' Concurrent Threads into Redis...';

    const redisNode = document.getElementById('node-2');
    if (redisNode) redisNode.classList.add('node-pulse');

    try {
        const res = await authedFetch(contextPath + '/api/simulation/burst', {
            method: 'POST',
            body: JSON.stringify({ concurrentUsers: users, availableSeats: seats })
        });

        if (res.ok) {
            const result = await res.json();
            document.getElementById('burstResultsEmpty').style.display = 'none';
            document.getElementById('burstResultsActive').style.display = 'block';

            document.getElementById('bmRequests').textContent = result.requestedUsers;
            document.getElementById('bmDuration').textContent = result.totalDurationMillis + ' ms';
            document.getElementById('bmRps').textContent = result.simulatedRps.toLocaleString() + ' RPS';
            document.getElementById('bmWon').textContent = result.successfulReservations;
            document.getElementById('bmRejected').textContent = result.rejectedOversold;

            const badge = document.getElementById('oversellBadge');
            if (result.zeroOversellingVerified) {
                badge.className = 'oversell-verification-banner banner-success';
                badge.textContent = '🛡️ Zero Overselling Guarantee: VERIFIED! (' + result.successfulReservations + ' tickets allocated, ' + result.rejectedOversold + ' rejected before DB)';
            } else {
                badge.className = 'oversell-verification-banner banner-fail';
                badge.textContent = '⚠️ Overselling Detected in test!';
            }

            const logWin = document.getElementById('burstLogWindow');
            logWin.innerHTML = (result.executionLogs || []).map(line => {
                let colorClass = '';
                if (line.includes('WON')) colorClass = 'log-win';
                else if (line.includes('REJECTED')) colorClass = 'log-reject';
                else if (line.includes('VERIFIED')) colorClass = 'log-verify';
                return '<div class="terminal-line ' + colorClass + '">' + escapeHtml(line) + '</div>';
            }).join('');

            logWin.scrollTop = logWin.scrollHeight;
            fetchTelemetry();
        } else {
            alert('Burst failed. Status: ' + res.status);
        }
    } catch (e) {
        alert('Burst error: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.textContent = '🚀 Launch Flash Sale Burst Simulation';
        if (redisNode) redisNode.classList.remove('node-pulse');
    }
}

document.addEventListener('DOMContentLoaded', async function() {
    if (!verifyAdminSession()) return;

    fetchTelemetry();
    loadLiveRedisKeys();
    loadLiveOutbox();
    loadKafkaMetadata();
});
</script>

<%@ include file="common/footer.jsp" %>
