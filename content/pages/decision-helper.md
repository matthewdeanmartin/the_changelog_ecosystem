Title: Decision Helper
Date: 2026-06-02
Slug: decision-helper
sortorder: 5
Summary: An interactive tool to help you find the best changelog manager for your project.

# Changelog Decision Helper

Answer a few questions to find the most suitable tool for your workflow.

<div id="decision-helper-app" class="helper-app">
    <div id="question-container">
        <h2 id="question-text">Loading...</h2>
        <div id="options-container" class="options-grid"></div>
    </div>
    <div id="result-container" style="display:none;">
        <h2>Recommended Tools</h2>
        <div id="tools-list"></div>
        <button onclick="resetHelper()" class="btn-reset">Start Over</button>
    </div>
</div>

<style>
.helper-app {
    background: #f4f4f9;
    padding: 2rem;
    border-radius: 8px;
    margin: 2rem 0;
    border: 1px solid #ddd;
}
.options-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-top: 1.5rem;
}
.btn-option {
    padding: 1rem;
    background: white;
    border: 2px solid #007bff;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
    transition: all 0.2s;
    text-align: left;
}
.btn-option:hover {
    background: #007bff;
    color: white;
}
.btn-reset {
    margin-top: 2rem;
    padding: 0.5rem 1rem;
    background: #6c757d;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}
.tool-card {
    background: white;
    padding: 1rem;
    margin-bottom: 1rem;
    border-left: 4px solid #28a745;
    border-radius: 0 4px 4px 0;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.tool-card h3 {
    margin-top: 0;
}
</style>

<script>
const tools = [
    { name: "git-cliff", ecosystem: ["rust", "cross"], method: "commits-conv", orchestrator: false, desc: "Fast, highly customizable changelog generator from git history. Works with any language." },
    { name: "semantic-release", ecosystem: ["node"], method: "commits-conv", orchestrator: true, desc: "Fully automated version management and package publishing. Highly opinionated." },
    { name: "release-it", ecosystem: ["node"], method: "commits-conv", orchestrator: true, desc: "Interactive CLI tool to automate versioning and package publishing. Very flexible." },
    { name: "towncrier", ecosystem: ["python"], method: "fragments", orchestrator: false, desc: "The gold standard for fragment-based changelogs in the Python ecosystem." },
    { name: "scriv", ecosystem: ["python", "cross"], method: "fragments", orchestrator: false, desc: "Modern fragment-based tool that works well with Markdown and multiple languages." },
    { name: "changie", ecosystem: ["go", "cross"], method: "fragments", orchestrator: false, desc: "User-friendly fragment tool with a focus on ease of use and cross-platform support." },
    { name: "changesets", ecosystem: ["node"], method: "fragments", orchestrator: true, desc: "Ideal for monorepos and Node.js projects. Uses a unique 'intent-to-release' workflow." },
    { name: "goreleaser", ecosystem: ["go"], method: "commits-conv", orchestrator: true, desc: "Release automation for Go projects, including cross-compilation and changelog generation." },
    { name: "release-plz", ecosystem: ["rust"], method: "commits-conv", orchestrator: true, desc: "Automates Rust crate releases, updating changelogs and publishing to crates.io." },
    { name: "auto-changelog", ecosystem: ["node", "cross"], method: "commits-generic", orchestrator: false, desc: "Simple tool that generates changelogs from git tags and commit history without strict schemas." },
    { name: "github-changelog-generator", ecosystem: ["ruby", "cross"], method: "commits-generic", orchestrator: false, desc: "Generates changelogs from GitHub issues, PRs, and tags." },
    { name: "versionize", ecosystem: ["dotnet"], method: "commits-conv", orchestrator: true, desc: "Conventional commits and changelog management for .NET projects." },
    { name: "dotnet-releaser", ecosystem: ["dotnet"], method: "commits-conv", orchestrator: true, desc: "All-in-one release CLI for .NET projects." },
    { name: "commit-and-tag-version", ecosystem: ["node"], method: "commits-conv", orchestrator: true, desc: "Automate versioning and CHANGELOG generation. A maintained fork of standard-version." },
    { name: "git-chglog", ecosystem: ["go", "cross"], method: "commits-conv", orchestrator: false, desc: "Highly configurable changelog generator that uses git tags and commits." }
];

let state = {
    step: 0,
    answers: {}
};

const questions = [
    {
        key: "ecosystem",
        text: "What is your primary ecosystem?",
        options: [
            { label: "Node.js", value: "node" },
            { label: "Python", value: "python" },
            { label: "Rust", value: "rust" },
            { label: "Go", value: "go" },
            { label: ".NET", value: "dotnet" },
            { label: "Other / Cross-platform", value: "cross" }
        ]
    },
    {
        key: "method",
        text: "How do you want to manage change metadata?",
        options: [
            { label: "Conventional Commits (e.g. feat: add login)", value: "commits-conv" },
            { label: "Generic Git History (tags, PR titles)", value: "commits-generic" },
            { label: "Separate Fragment Files (Newsfiles)", value: "fragments" }
        ]
    },
    {
        key: "orchestrator",
        text: "Do you want the tool to handle version bumping and publishing?",
        options: [
            { label: "Yes, automate the whole release", value: true },
            { label: "No, just generate the changelog", value: false }
        ]
    }
];

function renderStep() {
    if (state.step >= questions.length) {
        showResults();
        return;
    }

    const question = questions[state.step];
    const qText = document.getElementById('question-text');
    if (!qText) return;
    qText.innerText = question.text;
    const optionsContainer = document.getElementById('options-container');
    optionsContainer.innerHTML = '';

    question.options.forEach(opt => {
        const btn = document.createElement('button');
        btn.className = 'btn-option';
        btn.innerText = opt.label;
        btn.onclick = () => {
            state.answers[question.key] = opt.value;
            state.step++;
            renderStep();
        };
        optionsContainer.appendChild(btn);
    });
}

function showResults() {
    document.getElementById('question-container').style.display = 'none';
    document.getElementById('result-container').style.display = 'block';

    const filtered = tools.filter(t => {
        const ecoMatch = t.ecosystem.includes(state.answers.ecosystem) || t.ecosystem.includes("cross");
        const methodMatch = t.method === state.answers.method;
        const orchMatch = t.orchestrator === state.answers.orchestrator;
        
        return ecoMatch && methodMatch && orchMatch;
    });

    const list = document.getElementById('tools-list');
    list.innerHTML = '';

    if (filtered.length === 0) {
        // Fallback: just match ecosystem
        const fallback = tools.filter(t => t.ecosystem.includes(state.answers.ecosystem) || t.ecosystem.includes("cross")).slice(0, 3);
        list.innerHTML = '<p>No perfect match found, but these might work for your ecosystem:</p>';
        renderTools(fallback, list);
    } else {
        renderTools(filtered, list);
    }
}

function renderTools(toolsToRender, container) {
    toolsToRender.forEach(t => {
        const div = document.createElement('div');
        div.className = 'tool-card';
        div.innerHTML = `<h3>${t.name}</h3><p>${t.desc}</p><a href="/reviews/${t.name}/">View Review</a>`;
        container.appendChild(div);
    });
}

function resetHelper() {
    state = { step: 0, answers: {} };
    document.getElementById('question-container').style.display = 'block';
    document.getElementById('result-container').style.display = 'none';
    renderStep();
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', renderStep);
</script>
