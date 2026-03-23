// Documentation modal functionality
let currentModal = null;

// Documentation files mapping
const docFiles = {
    'README': 'README.md',
    'installation': 'installation.md',
    'getting-started': 'getting-started.md', 
    'interface-guide': 'interface-guide.md',
    'editing-features': 'editing-features.md',
    'file-management': 'file-management.md',
    'advanced-features': 'advanced-features.md',
    'preferences': 'preferences.md',
    'troubleshooting': 'troubleshooting.md'
};

// Show documentation modal
async function showDocumentation(docId = 'README') {
    try {
        if (!currentModal) {
            // Show loading modal immediately
            createLoadingModal();
        }
        
        const filename = docFiles[docId] || docFiles['README'];
        const response = await fetch(`docs/${filename}`);
        
        if (!response.ok) {
            throw new Error(`Failed to load documentation: ${response.status}`);
        }
        
        const markdownContent = await response.text();
        const htmlContent = marked.parse(markdownContent);
        
        if (currentModal && currentModal.classList.contains('loading-modal')) {
            // Replace loading modal with content modal
            currentModal.remove();
            currentModal = null;
            createDocumentationModal(docId, htmlContent);
        } else if (currentModal) {
            // Update existing modal content
            updateDocumentationModal(docId, htmlContent);
        } else {
            // Create new modal
            createDocumentationModal(docId, htmlContent);
        }
    } catch (error) {
        console.error('Error loading documentation:', error);
        if (currentModal && currentModal.classList.contains('loading-modal')) {
            currentModal.remove();
            currentModal = null;
        }
        showErrorModal('Failed to load documentation. Please try again.');
    }
}

// Create documentation modal
function createDocumentationModal(docId, htmlContent) {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    
    const modal = document.createElement('div');
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.8);
        z-index: 1000;
        display: flex;
        align-items: flex-start;
        justify-content: center;
        padding: 20px;
        overflow-y: auto;
    `;
    
    const modalContent = document.createElement('div');
    modalContent.style.cssText = `
        background: ${isDark ? '#1e293b' : 'white'};
        color: ${isDark ? '#e2e8f0' : '#1a1a1a'};
        border-radius: 16px;
        box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
        max-width: 900px;
        width: 100%;
        max-height: 90vh;
        overflow-y: auto;
        margin-top: 40px;
    `;
    
    // Header
    const header = document.createElement('div');
    header.style.cssText = `
        position: sticky;
        top: 0;
        background: ${isDark ? '#1e293b' : 'white'};
        border-bottom: 1px solid ${isDark ? '#475569' : '#e5e7eb'};
        padding: 20px 40px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-radius: 16px 16px 0 0;
    `;
    
    const title = document.createElement('h2');
    title.textContent = 'MDTool Documentation';
    title.style.cssText = `
        margin: 0;
        font-size: 24px;
        font-weight: 700;
    `;
    
    const closeButton = document.createElement('button');
    closeButton.textContent = '×';
    closeButton.style.cssText = `
        background: transparent;
        border: none;
        font-size: 28px;
        cursor: pointer;
        color: ${isDark ? '#94a3b8' : '#6b7280'};
        padding: 8px;
        line-height: 1;
        border-radius: 4px;
    `;
    closeButton.onclick = () => closeModal();
    
    // Navigation
    const navigation = createDocNavigation(docId, isDark);
    navigation.className = 'doc-navigation';
    
    const headerContent = document.createElement('div');
    headerContent.style.cssText = 'display: flex; align-items: center; gap: 20px;';
    headerContent.appendChild(title);
    headerContent.appendChild(navigation);
    
    header.appendChild(headerContent);
    header.appendChild(closeButton);
    
    // Content
    const content = document.createElement('div');
    content.className = 'doc-content';
    content.style.cssText = `
        padding: 40px;
        line-height: 1.6;
        ${isDark ? 'color: #e2e8f0;' : 'color: #1a1a1a;'}
    `;
    
    // Style the generated HTML content
    content.innerHTML = htmlContent;
    styleMarkdownContent(content, isDark);
    
    modalContent.appendChild(header);
    modalContent.appendChild(content);
    modal.appendChild(modalContent);
    
    // Event listeners
    modal.addEventListener('click', (e) => {
        if (e.target === modal) closeModal();
    });
    
    document.addEventListener('keydown', handleEscapeKey);
    
    document.body.appendChild(modal);
    currentModal = modal;
}

// Update existing documentation modal
function updateDocumentationModal(docId, htmlContent) {
    if (!currentModal) return;
    
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    
    // Update navigation buttons
    const navigation = currentModal.querySelector('.doc-navigation');
    if (navigation) {
        navigation.replaceWith(createDocNavigation(docId, isDark));
    }
    
    // Update content
    const content = currentModal.querySelector('.doc-content');
    if (content) {
        content.innerHTML = htmlContent;
        styleMarkdownContent(content, isDark);
    }
}

// Style the markdown content
function styleMarkdownContent(container, isDark) {
    // Style headers
    const headers = container.querySelectorAll('h1, h2, h3, h4, h5, h6');
    headers.forEach(h => {
        h.style.color = isDark ? '#f1f5f9' : '#1a1a1a';
        h.style.marginTop = h.tagName === 'H1' ? '0' : '32px';
        h.style.marginBottom = '16px';
    });
    
    // Style paragraphs
    const paragraphs = container.querySelectorAll('p');
    paragraphs.forEach(p => {
        p.style.color = isDark ? '#cbd5e1' : '#4b5563';
        p.style.marginBottom = '16px';
        p.style.lineHeight = '1.6';
    });
    
    // Style links
    const links = container.querySelectorAll('a');
    links.forEach(a => {
        a.style.color = '#667eea';
        a.style.textDecoration = 'none';
        
        // Handle internal doc links
        if (a.getAttribute('href')?.startsWith('#')) {
            a.onclick = (e) => {
                e.preventDefault();
                const docId = a.getAttribute('href').substring(1);
                if (docFiles[docId]) {
                    showDocumentation(docId);
                }
            };
        } else {
            a.target = '_blank';
        }
    });
    
    // Style code blocks
    const codeBlocks = container.querySelectorAll('pre');
    codeBlocks.forEach(pre => {
        pre.style.background = isDark ? '#0f172a' : '#f8fafc';
        pre.style.border = `1px solid ${isDark ? '#334155' : '#e2e8f0'}`;
        pre.style.borderRadius = '8px';
        pre.style.padding = '16px';
        pre.style.margin = '16px 0';
        pre.style.overflowX = 'auto';
        pre.style.fontSize = '14px';
        pre.style.fontFamily = 'monospace';
    });
    
    // Style inline code
    const inlineCodes = container.querySelectorAll('code:not(pre code)');
    inlineCodes.forEach(code => {
        code.style.background = isDark ? '#334155' : '#f1f5f9';
        code.style.padding = '2px 6px';
        code.style.borderRadius = '4px';
        code.style.fontSize = '14px';
        code.style.fontFamily = 'monospace';
    });
    
    // Style lists
    const lists = container.querySelectorAll('ul, ol');
    lists.forEach(list => {
        list.style.margin = '16px 0';
        list.style.paddingLeft = '24px';
    });
    
    const listItems = container.querySelectorAll('li');
    listItems.forEach(li => {
        li.style.margin = '8px 0';
    });
    
    // Style tables
    const tables = container.querySelectorAll('table');
    tables.forEach(table => {
        table.style.borderCollapse = 'collapse';
        table.style.width = '100%';
        table.style.margin = '16px 0';
    });
    
    const tableCells = container.querySelectorAll('th, td');
    tableCells.forEach(cell => {
        cell.style.border = `1px solid ${isDark ? '#475569' : '#e5e7eb'}`;
        cell.style.padding = '8px 12px';
    });
    
    const tableHeaders = container.querySelectorAll('th');
    tableHeaders.forEach(th => {
        th.style.background = isDark ? '#374151' : '#f9fafb';
        th.style.fontWeight = '600';
    });
}

// Create navigation
function createDocNavigation(currentDocId, isDark) {
    const nav = document.createElement('div');
    nav.style.cssText = 'display: flex; gap: 8px; flex-wrap: wrap;';
    
    const docList = [
        { id: 'README', label: 'Overview' },
        { id: 'installation', label: 'Install' },
        { id: 'getting-started', label: 'Start' },
        { id: 'interface-guide', label: 'Interface' },
        { id: 'editing-features', label: 'Editing' },
        { id: 'file-management', label: 'Files' },
        { id: 'advanced-features', label: 'Advanced' },
        { id: 'preferences', label: 'Settings' },
        { id: 'troubleshooting', label: 'Help' }
    ];
    
    docList.forEach(doc => {
        const button = document.createElement('button');
        button.textContent = doc.label;
        button.style.cssText = `
            background: ${doc.id === currentDocId ? '#667eea' : 'transparent'};
            color: ${doc.id === currentDocId ? '#ffffff' : (isDark ? '#94a3b8' : '#6b7280')};
            border: 1px solid ${doc.id === currentDocId ? '#667eea' : (isDark ? '#475569' : '#d1d5db')};
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.2s;
        `;
        
        if (doc.id !== currentDocId) {
            button.onclick = () => showDocumentation(doc.id);
        }
        
        nav.appendChild(button);
    });
    
    return nav;
}

// Close modal
function closeModal() {
    if (currentModal) {
        document.removeEventListener('keydown', handleEscapeKey);
        currentModal.remove();
        currentModal = null;
    }
}

// Handle escape key
function handleEscapeKey(e) {
    if (e.key === 'Escape') {
        closeModal();
    }
}

// Show error modal
function showErrorModal(message) {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    
    const modal = document.createElement('div');
    modal.innerHTML = `
        <div style="
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: ${isDark ? '#1e293b' : 'white'};
            color: ${isDark ? '#e2e8f0' : '#1a1a1a'};
            padding: 32px;
            border-radius: 12px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
            text-align: center;
            z-index: 1001;
            max-width: 400px;
        ">
            <div style="font-size: 48px; margin-bottom: 16px;">⚠️</div>
            <h3 style="margin: 0 0 16px 0; font-size: 18px;">Error</h3>
            <p style="margin: 0 0 24px 0; color: ${isDark ? '#94a3b8' : '#6b7280'};">${message}</p>
            <button onclick="this.closest('div').parentElement.remove()" style="
                background: #667eea;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            ">OK</button>
        </div>
        <div style="
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
        "></div>
    `;
    
    document.body.appendChild(modal);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (modal.parentNode) {
            modal.remove();
        }
    }, 5000);
}

// Create loading modal
function createLoadingModal() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    
    const modal = document.createElement('div');
    modal.classList.add('loading-modal');
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.8);
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
    `;
    
    const loadingContent = document.createElement('div');
    loadingContent.style.cssText = `
        background: ${isDark ? '#1e293b' : 'white'};
        color: ${isDark ? '#e2e8f0' : '#1a1a1a'};
        border-radius: 16px;
        padding: 40px;
        text-align: center;
        box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
    `;
    
    loadingContent.innerHTML = `
        <div style="font-size: 32px; margin-bottom: 16px;">📖</div>
        <h3 style="margin: 0 0 8px 0; font-size: 18px;">Loading Documentation</h3>
        <p style="margin: 0; color: ${isDark ? '#94a3b8' : '#6b7280'}; font-size: 14px;">Please wait...</p>
    `;
    
    modal.appendChild(loadingContent);
    document.body.appendChild(modal);
    currentModal = modal;
}