/**
 * Split a proxy list into usable entries.
 * ProxyScrape and similar providers may return CRLF, LF, or a mix of endings.
 * @param {string} text
 * @returns {string[]}
 */
export function parseProxyList(text) {
    if (typeof text !== 'string') {
        return [];
    }

    return text
        .split(/\r?\n/)
        .map(proxy => proxy.trim())
        .filter(proxy => proxy.length > 0);
}

/**
 * A traffic run only succeeds when it reaches the requested session count.
 * @param {number} successfulSessions
 * @param {number} targetSuccessfulSessions
 * @returns {number}
 */
export function resolveExitCode(successfulSessions, targetSuccessfulSessions) {
    return successfulSessions >= targetSuccessfulSessions ? 0 : 1;
}
