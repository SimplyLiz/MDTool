// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Platform detection for download buttons
function detectPlatform() {
    const userAgent = navigator.userAgent.toLowerCase();
    const platform = navigator.platform.toLowerCase();
    
    if (userAgent.includes('mac') || platform.includes('mac')) {
        return 'macos';
    } else if (userAgent.includes('win') || platform.includes('win')) {
        return 'windows';
    } else if (userAgent.includes('linux') || platform.includes('linux')) {
        return 'linux';
    }
    return 'unknown';
}

// Update primary download button based on platform
function updatePrimaryDownloadButton() {
    const platform = detectPlatform();
    const primaryButton = document.querySelector('.hero-buttons .btn-primary');
    const downloadButtons = document.querySelectorAll('.btn-download');
    
    if (primaryButton) {
        switch (platform) {
            case 'macos':
                primaryButton.textContent = 'Download for macOS';
                break;
            case 'windows':
                primaryButton.textContent = 'Download for Windows';
                break;
            case 'linux':
                primaryButton.textContent = 'Download for Linux';
                break;
            default:
                primaryButton.textContent = 'Download';
        }
    }
    
    // Highlight the appropriate platform in download section
    downloadButtons.forEach(button => {
        const buttonText = button.querySelector('.download-title').textContent;
        if ((platform === 'macos' && buttonText.includes('macOS')) ||
            (platform === 'windows' && buttonText.includes('Windows'))) {
            button.style.borderColor = '#667eea';
            button.style.background = '#f8fafc';
        }
    });
}

// Animate elements on scroll
function animateOnScroll() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe feature cards
    document.querySelectorAll('.feature-card').forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = `all 0.6s ease-out ${index * 0.1}s`;
        observer.observe(card);
    });
    
    // Observe platform cards
    document.querySelectorAll('.platform-card').forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = `all 0.6s ease-out ${index * 0.2}s`;
        observer.observe(card);
    });
    
    // Observe tech items
    document.querySelectorAll('.tech-item').forEach((item, index) => {
        item.style.opacity = '0';
        item.style.transform = 'translateY(20px)';
        item.style.transition = `all 0.5s ease-out ${index * 0.1}s`;
        observer.observe(item);
    });
}

// Header scroll effect
function handleHeaderScroll() {
    const header = document.querySelector('.header');
    let lastScrollY = window.scrollY;
    
    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
        
        if (currentScrollY > 100) {
            if (isDark) {
                header.style.background = 'rgba(15, 23, 42, 0.98)';
                header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.3)';
            } else {
                header.style.background = 'rgba(255, 255, 255, 0.98)';
                header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
            }
        } else {
            if (isDark) {
                header.style.background = 'rgba(15, 23, 42, 0.95)';
                header.style.boxShadow = 'none';
            } else {
                header.style.background = 'rgba(255, 255, 255, 0.95)';
                header.style.boxShadow = 'none';
            }
        }
        
        // Hide header on scroll down, show on scroll up
        if (currentScrollY > lastScrollY && currentScrollY > 200) {
            header.style.transform = 'translateY(-100%)';
        } else {
            header.style.transform = 'translateY(0)';
        }
        
        lastScrollY = currentScrollY;
    });
}

// Add click handlers for download buttons
function setupDownloadHandlers() {
    // Hero download buttons
    document.querySelectorAll('.hero-buttons .btn-primary, .hero-buttons .btn-secondary').forEach(button => {
        button.addEventListener('click', function() {
            const buttonText = this.textContent;
            let downloadUrl = '';
            
            if (buttonText.includes('macOS')) {
                downloadUrl = 'http://tastehub.io/downloads/MDTool.zip';
            } else if (buttonText.includes('Windows')) {
                downloadUrl = 'http://tastehub.io/downloads/windows.zip';
            }
            
            if (downloadUrl) {
                // Create a temporary link element to trigger download
                const link = document.createElement('a');
                link.href = downloadUrl;
                link.download = '';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                showDownloadMessage(buttonText);
            } else {
                // If no specific platform detected, scroll to download section
                document.querySelector('#download').scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Main download buttons
    document.querySelectorAll('.btn-download').forEach(button => {
        button.addEventListener('click', function() {
            const platform = this.querySelector('.download-title').textContent;
            
            let downloadUrl = '';
            if (platform.includes('macOS')) {
                downloadUrl = 'http://tastehub.io/downloads/MDTool.zip';
            } else if (platform.includes('Windows')) {
                downloadUrl = 'http://tastehub.io/downloads/windows.zip';
            }
            
            if (downloadUrl) {
                // Create a temporary link element to trigger download
                const link = document.createElement('a');
                link.href = downloadUrl;
                link.download = '';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                
                showDownloadMessage(platform);
            }
        });
    });
    
        // Other placeholder links (excluding documentation which now has onclick handlers)
    document.querySelectorAll('.download-link').forEach(link => {
        link.addEventListener('click', function(e) {
            if (this.getAttribute('href') === '#' && !this.hasAttribute('onclick')) {
                e.preventDefault();
                console.log(`Navigate to: ${this.textContent}`);
                showComingSoonMessage(this.textContent);
            }
        });
    });
    
    // Exclude theme toggle from the above handler
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) {
        // Remove any existing event listeners from theme toggle
        themeToggle.removeEventListener('click', showComingSoonMessage);
    }
}

// Show download message
function showDownloadMessage(platform) {
    const message = document.createElement('div');
    message.className = 'download-message';
    message.innerHTML = `
        <div class="message-content">
            <div class="message-icon">📥</div>
            <div class="message-text">
                <h4>Download Starting</h4>
                <p>${platform} download will begin shortly...</p>
            </div>
            <button class="message-close">&times;</button>
        </div>
    `;
    
    // Add styles for the message
    message.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        background: white;
        border-radius: 12px;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        border: 1px solid #e2e8f0;
        z-index: 1000;
        animation: slideIn 0.3s ease-out;
    `;
    
    const messageContent = message.querySelector('.message-content');
    messageContent.style.cssText = `
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 16px 20px;
    `;
    
    const messageIcon = message.querySelector('.message-icon');
    messageIcon.style.fontSize = '24px';
    
    const messageText = message.querySelector('.message-text');
    messageText.querySelector('h4').style.cssText = 'margin: 0; font-size: 14px; font-weight: 600;';
    messageText.querySelector('p').style.cssText = 'margin: 0; font-size: 12px; color: #6b7280;';
    
    const closeButton = message.querySelector('.message-close');
    closeButton.style.cssText = `
        background: none;
        border: none;
        font-size: 20px;
        cursor: pointer;
        color: #9ca3af;
        padding: 0;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
    `;
    
    closeButton.addEventListener('click', () => {
        message.remove();
    });
    
    document.body.appendChild(message);
    
    // Auto-remove after 3 seconds
    setTimeout(() => {
        if (message.parentNode) {
            message.remove();
        }
    }, 3000);
}

// Show coming soon message
function showComingSoonMessage(action) {
    const message = document.createElement('div');
    message.innerHTML = `
        <div style="
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: white;
            padding: 32px;
            border-radius: 12px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
            text-align: center;
            z-index: 1000;
        ">
            <div style="font-size: 48px; margin-bottom: 16px;">🚀</div>
            <h3 style="margin: 0 0 8px 0; font-size: 18px;">Coming Soon</h3>
            <p style="margin: 0; color: #6b7280;">${action} will be available soon!</p>
        </div>
        <div style="
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            z-index: 999;
        "></div>
    `;
    
    document.body.appendChild(message);
    
    // Click to close
    message.addEventListener('click', () => {
        message.remove();
    });
    
    // Auto-remove after 2 seconds
    setTimeout(() => {
        if (message.parentNode) {
            message.remove();
        }
    }, 2000);
}

// Show Impressum
function showImpressum() {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const message = document.createElement('div');
    message.innerHTML = `
        <div style="
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.8);
            z-index: 999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        ">
            <div style="
                background: ${isDark ? '#1e293b' : 'white'};
                color: ${isDark ? '#e2e8f0' : '#1a1a1a'};
                padding: 40px;
                border-radius: 16px;
                box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25);
                max-width: 600px;
                max-height: 80vh;
                overflow-y: auto;
                position: relative;
            ">
                <button onclick="this.parentElement.parentElement.remove()" style="
                    position: absolute;
                    top: 16px;
                    right: 16px;
                    background: transparent;
                    border: none;
                    font-size: 24px;
                    cursor: pointer;
                    color: ${isDark ? '#94a3b8' : '#6b7280'};
                    padding: 8px;
                    line-height: 1;
                ">&times;</button>
                
                <h2 style="margin: 0 0 24px 0; font-size: 24px; font-weight: 700;">Impressum</h2>
                
                <div style="line-height: 1.6; font-size: 14px;">
                    <p style="margin: 0 0 16px 0; font-weight: 600;">Company Information:</p>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>TasteHub GmbH</strong><br>
                        Franzengasse 5<br>
                        1050 Vienna<br>
                        Austria
                    </p>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>Contact:</strong><br>
                        Email: info@tastehub.io<br>
                        Support: support@tastehub.io
                    </p>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>Commercial Register:</strong><br>
                        Register court: Handelsgericht Wien<br>
                        Register number: FN 123456a
                    </p>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>VAT Identification Number:</strong><br>
                        ATU12345678
                    </p>
                    
                    <h3 style="margin: 24px 0 16px 0; font-size: 18px; font-weight: 600;">Disclaimer:</h3>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>Liability for content</strong><br>
                        The contents of our pages have been created with the utmost care. However, we cannot guarantee the contents' accuracy, completeness or topicality. We are responsible for our own content on these web pages according to general law.
                    </p>
                    
                    <p style="margin: 0 0 16px 0;">
                        <strong>Liability for links</strong><br>
                        Our website contains links to external third-party websites. We have no influence on the contents of those websites, therefore we cannot guarantee those contents. The respective providers or operators of the websites are always responsible for the contents of the linked pages.
                    </p>
                    
                    <p style="margin: 0 0 0 0;">
                        <strong>Copyright</strong><br>
                        The content and works on these pages created by TasteHub GmbH are subject to Austrian and international copyright law. The reproduction, editing, distribution and any kind of use outside the limits of copyright law require the written consent of the respective author or creator.
                    </p>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(message);
}

// Add CSS animation keyframes
function addAnimationStyles() {
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        .header {
            transition: all 0.3s ease-out;
        }
    `;
    document.head.appendChild(style);
}

// Dark Mode Functionality
function initializeTheme() {
    const savedTheme = localStorage.getItem('mdtool-theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const systemTheme = systemPrefersDark ? 'dark' : 'light';
    const initialTheme = savedTheme || systemTheme;
    
    console.log('System prefers dark:', systemPrefersDark);
    console.log('Saved theme:', savedTheme);
    console.log('Initial theme:', initialTheme);
    
    setTheme(initialTheme);
    
    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!localStorage.getItem('mdtool-theme')) {
            const newTheme = e.matches ? 'dark' : 'light';
            console.log('System theme changed to:', newTheme);
            setTheme(newTheme);
        }
    });
}

function setTheme(theme) {
    const html = document.documentElement;
    const themeToggle = document.getElementById('theme-toggle');
    const themeIcon = themeToggle?.querySelector('.theme-icon');
    
    console.log('Setting theme to:', theme);
    
    if (theme === 'dark') {
        html.setAttribute('data-theme', 'dark');
        if (themeIcon) {
            themeIcon.textContent = '☀️';
            console.log('Set icon to sun');
        }
    } else {
        html.setAttribute('data-theme', 'light');
        if (themeIcon) {
            themeIcon.textContent = '🌙';
            console.log('Set icon to moon');
        }
    }
    
    // Update header background immediately after theme change
    updateHeaderBackground();
}

function updateHeaderBackground() {
    const header = document.querySelector('.header');
    const currentScrollY = window.scrollY;
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    
    if (currentScrollY > 100) {
        if (isDark) {
            header.style.background = 'rgba(15, 23, 42, 0.98)';
            header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.3)';
        } else {
            header.style.background = 'rgba(255, 255, 255, 0.98)';
            header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
        }
    } else {
        if (isDark) {
            header.style.background = 'rgba(15, 23, 42, 0.95)';
            header.style.boxShadow = 'none';
        } else {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.boxShadow = 'none';
        }
    }
}

function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-theme') || 'light';
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    console.log('Toggling theme from', currentTheme, 'to', newTheme);
    
    setTheme(newTheme);
    localStorage.setItem('mdtool-theme', newTheme);
}

function setupThemeToggle() {
    const themeToggle = document.getElementById('theme-toggle');
    console.log('Theme toggle element:', themeToggle);
    
    if (themeToggle) {
        themeToggle.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Theme toggle clicked');
            toggleTheme();
        });
        
        console.log('Theme toggle event listener added');
    } else {
        console.error('Theme toggle element not found');
    }
}

// Initialize all functionality when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeTheme();
    setupThemeToggle();
    updatePrimaryDownloadButton();
    animateOnScroll();
    handleHeaderScroll();
    setupDownloadHandlers();
    addAnimationStyles();
});

// Add some interactive effects
document.addEventListener('DOMContentLoaded', function() {
    // Add hover effect to mockup
    const windowFrame = document.querySelector('.window-frame');
    if (windowFrame) {
        windowFrame.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.02)';
            this.style.transition = 'transform 0.3s ease-out';
        });
        
        windowFrame.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
        });
    }
    
    // Add typing animation to editor mockup
    const markdownLines = document.querySelectorAll('.markdown-line');
    if (markdownLines.length > 0) {
        // Start typing animation after a delay
        setTimeout(() => {
            markdownLines.forEach((line, index) => {
                setTimeout(() => {
                    line.style.opacity = '0.5';
                    setTimeout(() => {
                        line.style.opacity = '1';
                        line.style.background = 'rgba(102, 126, 234, 0.1)';
                        setTimeout(() => {
                            line.style.background = 'transparent';
                        }, 500);
                    }, 200);
                }, index * 300);
            });
        }, 1000);
    }
});