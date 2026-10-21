import test from 'node:test';
import assert from 'node:assert/strict';

import { parseProxyList, resolveExitCode } from '../proxy-helpers.js';

test('parseProxyList accepts CRLF lists', () => {
    assert.deepEqual(
        parseProxyList('1.1.1.1:8080\r\n2.2.2.2:8080\r\n'),
        ['1.1.1.1:8080', '2.2.2.2:8080']
    );
});

test('parseProxyList accepts LF lists', () => {
    assert.deepEqual(
        parseProxyList('1.1.1.1:8080\n2.2.2.2:8080\n'),
        ['1.1.1.1:8080', '2.2.2.2:8080']
    );
});

test('parseProxyList handles mixed endings, blank lines and whitespace', () => {
    assert.deepEqual(
        parseProxyList('  a  \r\n\r\n b \n c \r\n  '),
        ['a', 'b', 'c']
    );
});

test('parseProxyList returns an empty list for empty content', () => {
    assert.deepEqual(parseProxyList(''), []);
    assert.deepEqual(parseProxyList('  \r\n \n '), []);
    assert.deepEqual(parseProxyList(null), []);
});

test('resolveExitCode returns 0 when the target is reached', () => {
    assert.equal(resolveExitCode(2, 2), 0);
    assert.equal(resolveExitCode(3, 2), 0);
    assert.equal(resolveExitCode(0, 0), 0);
});

test('resolveExitCode returns 1 below the target', () => {
    assert.equal(resolveExitCode(0, 2), 1);
    assert.equal(resolveExitCode(1, 2), 1);
});
