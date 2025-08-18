import Cocoa
import Quartz
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider {
    
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        
        // Read the markdown file
        let data = try Data(contentsOf: request.fileURL)
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "MarkdownQLPreview", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Could not read markdown file"])
        }
        
        // Convert markdown to HTML
        let html = convertMarkdownToHTML(markdown)
        
        // Return HTML content
        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 800, height: 600)) { reply in
            reply.stringEncoding = .utf8
            return html.data(using: .utf8) ?? Data()
        }
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // Simplified but robust markdown parser
        var html = markdown
        
        // First, escape HTML entities in the content
        html = html
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        // Process code blocks first (protect from other processing)
        html = processCodeBlocks(html)
        
        // Process other markdown elements
        html = processHeaders(html)
        html = processLists(html)
        html = processInlineElements(html)
        
        // Convert line breaks to proper HTML
        html = html.replacingOccurrences(of: "\n\n", with: "</p>\n<p>")
        html = html.replacingOccurrences(of: "\n", with: "<br>")
        
        // Wrap in paragraphs
        html = "<p>" + html + "</p>"
        
        // Clean up empty paragraphs
        html = html.replacingOccurrences(of: "<p></p>", with: "")
        html = html.replacingOccurrences(of: "<p><br></p>", with: "")
        
        return wrapInHTML(html)
    }
    
    private func processCodeBlocks(_ text: String) -> String {
        // Handle code blocks with ``` 
        let codeBlockPattern = #"```(\w*)\n(.*?)\n```"#
        return text.replacingOccurrences(
            of: codeBlockPattern,
            with: "<pre><code class=\"language-$1\">$2</code></pre>",
            options: .regularExpression
        )
    }
    
    private func processHeaders(_ text: String) -> String {
        var result = text
        
        // Process headers (# ## ### etc.)
        result = result.replacingOccurrences(of: #"^######\s+(.+)$"#, with: "<h6>$1</h6>", options: [.regularExpression, .anchored])
        result = result.replacingOccurrences(of: #"^#####\s+(.+)$"#, with: "<h5>$1</h5>", options: [.regularExpression, .anchored])
        result = result.replacingOccurrences(of: #"^####\s+(.+)$"#, with: "<h4>$1</h4>", options: [.regularExpression, .anchored])
        result = result.replacingOccurrences(of: #"^###\s+(.+)$"#, with: "<h3>$1</h3>", options: [.regularExpression, .anchored])
        result = result.replacingOccurrences(of: #"^##\s+(.+)$"#, with: "<h2>$1</h2>", options: [.regularExpression, .anchored])
        result = result.replacingOccurrences(of: #"^#\s+(.+)$"#, with: "<h1>$1</h1>", options: [.regularExpression, .anchored])
        
        return result
    }
    
    private func processLists(_ text: String) -> String {
        var result = text
        
        // Handle unordered lists
        result = result.replacingOccurrences(of: #"^[*+-]\s+(.+)$"#, with: "<li>$1</li>", options: [.regularExpression, .anchored])
        
        // Handle ordered lists  
        result = result.replacingOccurrences(of: #"^\d+\.\s+(.+)$"#, with: "<li>$1</li>", options: [.regularExpression, .anchored])
        
        // Wrap consecutive <li> elements in <ul> tags
        result = result.replacingOccurrences(of: #"(<li>.*?</li>(\n<li>.*?</li>)*)"#, with: "<ul>$1</ul>", options: .regularExpression)
        
        return result
    }
    
    private func processInlineElements(_ text: String) -> String {
        var result = text
        
        // Bold text
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        result = result.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)
        
        // Italic text
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        result = result.replacingOccurrences(of: #"_(.+?)_"#, with: "<em>$1</em>", options: .regularExpression)
        
        // Inline code
        result = result.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        // Links
        result = result.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // Images  
        result = result.replacingOccurrences(of: #"!\[(.+?)\]\((.+?)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)
        
        return result
    }
    
    // Legacy method for compatibility - now simplified
    private func formatInlineElements(_ text: String) -> String {
        return processInlineElements(text)
    }
    
    // Remove the old complex parsing logic
    private func oldConvertMarkdownToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var inCodeBlock = false
        var inList = false
        var inOrderedList = false
        var inBlockquote = false
        var inTable = false
        var tableHeaders: [String] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Code blocks
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    processedLines.append("</code></pre>")
                    inCodeBlock = false
                } else {
                    let language = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    processedLines.append("<pre><code class=\"language-\(language)\">")
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                // Escape HTML entities in code content
                let escapedLine = line
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                processedLines.append(escapedLine)
                continue
            }
            
            // Tables
            if trimmedLine.contains("|") && !trimmedLine.isEmpty {
                let cells = trimmedLine.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
                
                if index < lines.count - 1 {
                    let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                    if nextLine.contains("|") && nextLine.contains("-") {
                        // This is a header row
                        if !inTable {
                            processedLines.append("<table>")
                            processedLines.append("<thead><tr>")
                            inTable = true
                        }
                        for cell in cells {
                            if !cell.isEmpty {
                                processedLines.append("<th>\(formatInlineElements(cell))</th>")
                            }
                        }
                        processedLines.append("</tr></thead><tbody>")
                        tableHeaders = cells.filter { !$0.isEmpty }
                        continue
                    }
                }
                
                if inTable && !nextLineIsTableSeparator(index: index, lines: lines) {
                    // Regular table row
                    processedLines.append("<tr>")
                    for cell in cells {
                        if !cell.isEmpty {
                            processedLines.append("<td>\(formatInlineElements(cell))</td>")
                        }
                    }
                    processedLines.append("</tr>")
                    continue
                } else if nextLineIsTableSeparator(index: index, lines: lines) {
                    // Skip separator line
                    continue
                }
            } else if inTable {
                processedLines.append("</tbody></table>")
                inTable = false
            }
            
            // Headers
            if trimmedLine.hasPrefix("######") {
                let content = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h6>\(formatInlineElements(content))</h6>")
            } else if trimmedLine.hasPrefix("#####") {
                let content = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h5>\(formatInlineElements(content))</h5>")
            } else if trimmedLine.hasPrefix("####") {
                let content = String(trimmedLine.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h4>\(formatInlineElements(content))</h4>")
            } else if trimmedLine.hasPrefix("###") {
                let content = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h3>\(formatInlineElements(content))</h3>")
            } else if trimmedLine.hasPrefix("##") {
                let content = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h2>\(formatInlineElements(content))</h2>")
            } else if trimmedLine.hasPrefix("#") {
                let content = String(trimmedLine.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                processedLines.append("<h1>\(formatInlineElements(content))</h1>")
            }
            // Horizontal rules
            else if trimmedLine == "---" || trimmedLine == "***" || trimmedLine == "___" {
                processedLines.append("<hr>")
            }
            // Blockquotes
            else if trimmedLine.hasPrefix(">") {
                let content = String(trimmedLine.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                if !inBlockquote {
                    processedLines.append("<blockquote>")
                    inBlockquote = true
                }
                processedLines.append("<p>\(formatInlineElements(content))</p>")
                
                // Check if next line is not a blockquote
                if index == lines.count - 1 || !lines[index + 1].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    processedLines.append("</blockquote>")
                    inBlockquote = false
                }
            }
            // Unordered lists
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("+ ") {
                if !inList {
                    processedLines.append("<ul>")
                    inList = true
                }
                let content = String(trimmedLine.dropFirst(2))
                
                // Check for task list
                if content.hasPrefix("[ ] ") {
                    let taskContent = String(content.dropFirst(4))
                    processedLines.append("<li><input type=\"checkbox\" disabled> \(formatInlineElements(taskContent))</li>")
                } else if content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
                    let taskContent = String(content.dropFirst(4))
                    processedLines.append("<li><input type=\"checkbox\" disabled checked> \(formatInlineElements(taskContent))</li>")
                } else {
                    processedLines.append("<li>\(formatInlineElements(content))</li>")
                }
            }
            // Ordered lists
            else if let match = trimmedLine.firstMatch(of: /^\d+\.\s+(.*)/) {
                if !inOrderedList {
                    processedLines.append("<ol>")
                    inOrderedList = true
                }
                let content = String(match.1)
                processedLines.append("<li>\(formatInlineElements(content))</li>")
            }
            // Empty lines or regular text
            else {
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                if inOrderedList {
                    processedLines.append("</ol>")
                    inOrderedList = false
                }
                if !trimmedLine.isEmpty {
                    processedLines.append("<p>\(formatInlineElements(line))</p>")
                } else {
                    processedLines.append("")
                }
            }
        }
        
        // Close any open lists
        if inList {
            processedLines.append("</ul>")
        }
        if inOrderedList {
            processedLines.append("</ol>")
        }
        if inCodeBlock {
            processedLines.append("</code></pre>")
        }
        if inTable {
            processedLines.append("</tbody></table>")
        }
        if inBlockquote {
            processedLines.append("</blockquote>")
        }
        
        let body = processedLines.joined(separator: "\n")
        
        // Wrap in full HTML document with enhanced styling
        return wrapInHTML(body)
    }
    
    private func nextLineIsTableSeparator(index: Int, lines: [String]) -> Bool {
        guard index < lines.count - 1 else { return false }
        let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
        return nextLine.contains("|") && nextLine.contains("-")
    }
    
    private func wrapInHTML(_ body: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Markdown Preview</title>
            <style>
                /* Base styles */
                * {
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    max-width: 900px;
                    margin: 0 auto;
                    padding: 30px 20px;
                    color: #333;
                    background-color: #fff;
                    word-wrap: break-word;
                }
                
                /* Headers */
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                    color: #111;
                }
                
                h1 {
                    font-size: 2em;
                    border-bottom: 2px solid #eaecef;
                    padding-bottom: 0.3em;
                    margin-top: 0;
                }
                
                h2 {
                    font-size: 1.5em;
                    border-bottom: 1px solid #eaecef;
                    padding-bottom: 0.3em;
                }
                
                h3 { font-size: 1.25em; }
                h4 { font-size: 1.1em; }
                h5 { font-size: 1em; }
                h6 { font-size: 0.9em; color: #6a737d; }
                
                /* Paragraphs and text */
                p {
                    margin-top: 0;
                    margin-bottom: 16px;
                }
                
                strong { font-weight: 600; }
                
                /* Links */
                a {
                    color: #0366d6;
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
                /* Code */
                code {
                    padding: 0.2em 0.4em;
                    margin: 0;
                    font-size: 85%;
                    background-color: rgba(175, 184, 193, 0.2);
                    border-radius: 6px;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
                }
                
                pre {
                    margin-top: 0;
                    margin-bottom: 16px;
                    padding: 16px;
                    overflow: auto;
                    font-size: 85%;
                    line-height: 1.45;
                    background-color: #f6f8fa;
                    border-radius: 6px;
                    border: 1px solid #e1e4e8;
                }
                
                pre code {
                    display: inline;
                    max-width: auto;
                    padding: 0;
                    margin: 0;
                    overflow: visible;
                    line-height: inherit;
                    word-wrap: normal;
                    background-color: transparent;
                    border: 0;
                    font-size: 100%;
                }
                
                /* Blockquotes */
                blockquote {
                    margin: 0 0 16px 0;
                    padding: 0 1em;
                    color: #6a737d;
                    border-left: 4px solid #dfe2e5;
                }
                
                blockquote > :first-child {
                    margin-top: 0;
                }
                
                blockquote > :last-child {
                    margin-bottom: 0;
                }
                
                /* Lists */
                ul, ol {
                    margin-top: 0;
                    margin-bottom: 16px;
                    padding-left: 2em;
                }
                
                ul ul, ul ol, ol ol, ol ul {
                    margin-top: 0;
                    margin-bottom: 0;
                }
                
                li {
                    margin-bottom: 0.25em;
                }
                
                li > p {
                    margin-top: 16px;
                }
                
                li + li {
                    margin-top: 0.25em;
                }
                
                /* Task lists */
                input[type="checkbox"] {
                    margin-right: 0.5em;
                    vertical-align: middle;
                }
                
                /* Tables */
                table {
                    border-spacing: 0;
                    border-collapse: collapse;
                    margin-top: 0;
                    margin-bottom: 16px;
                    width: 100%;
                    overflow: auto;
                }
                
                table th {
                    font-weight: 600;
                    padding: 6px 13px;
                    border: 1px solid #d1d5da;
                    background-color: #f6f8fa;
                }
                
                table td {
                    padding: 6px 13px;
                    border: 1px solid #d1d5da;
                }
                
                table tr {
                    background-color: #fff;
                    border-top: 1px solid #c6cbd1;
                }
                
                table tr:nth-child(2n) {
                    background-color: #f6f8fa;
                }
                
                /* Horizontal rules */
                hr {
                    height: 0.25em;
                    padding: 0;
                    margin: 24px 0;
                    background-color: #e1e4e8;
                    border: 0;
                }
                
                /* Images */
                img {
                    max-width: 100%;
                    box-sizing: content-box;
                    background-color: #fff;
                    border-radius: 6px;
                    margin: 16px 0;
                }
                
                /* Strikethrough */
                del {
                    text-decoration: line-through;
                    color: #6a737d;
                }
                
                /* Dark mode support */
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #0d1117;
                        color: #c9d1d9;
                    }
                    
                    h1, h2, h3, h4, h5, h6 {
                        color: #f0f6fc;
                    }
                    
                    h1, h2 {
                        border-bottom-color: #30363d;
                    }
                    
                    h6 {
                        color: #8b949e;
                    }
                    
                    code {
                        background-color: rgba(110, 118, 129, 0.2);
                    }
                    
                    pre {
                        background-color: #161b22;
                        border-color: #30363d;
                    }
                    
                    blockquote {
                        border-left-color: #3b434b;
                        color: #8b949e;
                    }
                    
                    table th {
                        background-color: #161b22;
                        border-color: #30363d;
                    }
                    
                    table td {
                        border-color: #30363d;
                    }
                    
                    table tr {
                        background-color: #0d1117;
                        border-top-color: #262c32;
                    }
                    
                    table tr:nth-child(2n) {
                        background-color: #161b22;
                    }
                    
                    hr {
                        background-color: #30363d;
                    }
                    
                    a {
                        color: #58a6ff;
                    }
                    
                    del {
                        color: #8b949e;
                    }
                }
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}