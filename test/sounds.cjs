// From kora_sound: node test/sounds.cjs /path/to/howler.core.js [client/html/index.html]
// Actual Howler 2.1.1 + shipped message handler; inert Audio and controlled timers.
// No audio-file/network loading, browser playback, or in-game memory claim.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const provider = process.argv[2];
assert(provider, 'supply the pinned Howler 2.1.1 source path');
const html = process.argv[3] || path.join(__dirname, '../client/html/index.html');
const timers = new Map();
let nextTimer = 0;
const context = {
    console,
    window: {
        navigator: { userAgent: 'fixture', platform: 'fixture', appVersion: 'fixture', vendor: '' },
        location: { protocol: 'https:' },
        addEventListener(name, fn) { if (name === 'message') this.message = fn; },
    },
    setTimeout(fn, delay) { const id = ++nextTimer; timers.set(id, { fn, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
    // The browser Audio constructor returns a host object; this fixture records
    // listeners and drives their real Howler callbacks without loading any URL.
    Audio: function () {
        const listeners = {};
        return {
            muted: false, paused: true, ended: false, duration: 1, currentTime: 0, readyState: 4,
            oncanplaythrough: null,
            canPlayType() { return 'probably'; },
            addEventListener(name, fn) { listeners[name] = fn; },
            removeEventListener(name, fn) { if (listeners[name] === fn) delete listeners[name]; },
            load() { if (listeners.canplaythrough) listeners.canplaythrough(); },
            play() { this.paused = false; this.ended = false; },
            pause() { this.paused = true; },
            fire(name) { if (listeners[name]) listeners[name](); },
        };
    },
    module: { exports: {} },
};
context.exports = context.module.exports;
vm.createContext(context);
vm.runInContext(fs.readFileSync(provider, 'utf8'), context, { filename: provider });
const { Howl, Howler } = context.module.exports;
context.Howl = Howl;
const script = fs.readFileSync(html, 'utf8').match(/<script>\s*([\s\S]*?)<\/script>/);
assert(script, 'inline message handler is present');
vm.runInContext(script[1], context, { filename: html });
let checks = 0;
function eq(actual, expected, message) { checks++; assert.equal(actual, expected, message); }
function flush() {
    for (const [id, timer] of timers) {
        if (timer.delay === 0) { timers.delete(id); timer.fn(); }
    }
}
function play(id, loop = false) {
    context.window.message({ data: {
        transactionType: 'playSound', transactionId: id, transactionLoop: loop,
        transactionFile: 'demo', transactionVolume: 0.42,
    } });
    const group = id ? context.activeSounds[id] : context.lastOneShot;
    flush();
    return group;
}
function stop(id) {
    context.window.message({ data: { transactionType: 'stopSound', transactionId: id } });
    flush();
}
function end(group, deliver = true) {
    const sound = group._sounds[0];
    sound._node.ended = true;
    const timer = group._endTimers[sound._id];
    if (typeof timer === 'function') sound._node.fire('ended');
    else { const pending = timers.get(timer); assert(pending, 'actual loop completion timer exists'); timers.delete(timer); pending.fn(); }
    if (deliver) flush();
}
// A group owned elsewhere must survive every resource-owned release.
const foreign = new Howl({ src: ['external.ogg'], preload: false });
const first = play('alarm', true);
eq(first._src, './sounds/demo.ogg', 'file path is unchanged');
eq(first.volume(), 0.42, 'volume is unchanged');
eq(first.loop(), true, 'loop option is unchanged');
const replacement = play('alarm', true);
eq(Howler._howls.length, 2, 'named replacement unloads old group, keeping foreign + active group');
eq(first.state(), 'unloaded', 'old named group is unloaded');
stop('alarm');
eq(Howler._howls.length, 1, 'explicit stop releases owned group');
eq(replacement.state(), 'unloaded');
eq(context.activeSounds.alarm, undefined);
stop('alarm'); stop('missing'); stop();
eq(Howler._howls.length, 1, 'duplicate and unknown stops remain harmless');

const untracked = play();
const latest = play();
eq(untracked.state(), 'unloaded', 'untracked replacement releases prior group');
eq(Howler._howls.length, 2);
end(latest);
eq(Howler._howls.length, 1, 'completed untracked one-shot releases group');
eq(context.lastOneShot, null);
const named = play('named');
end(named);
eq(Howler._howls.length, 1, 'completed named one-shot releases group');
eq(context.activeSounds.named, undefined);
stop('named');
eq(Howler._howls.length, 1, 'completed id no longer owns a group');

const loop = play('loop', true);
end(loop);
eq(Howler._howls.length, 2, 'a loop iteration keeps its active group');
eq(context.activeSounds.loop, loop);
eq(loop.playing(), true);
stop('loop');
eq(Howler._howls.length, 1);
// Howler emits end asynchronously. Queue the old callback, then reuse its id.
const retired = play('reuse');
end(retired, false);
const newer = play('reuse', true);
eq(context.activeSounds.reuse, newer, 'late old completion cannot clear replacement id');
eq(newer.playing(), true);
eq(Howler._howls.length, 2);
stop('reuse');
eq(Howler._howls.length, 1);
const retiredUntracked = play();
end(retiredUntracked, false);
const newerUntracked = play(undefined, true);
eq(context.lastOneShot, newerUntracked, 'late old completion cannot clear newer untracked group');
eq(newerUntracked.playing(), true);
const finalUntracked = play();
end(finalUntracked);
eq(Howler._howls.length, 1);

const a = play('a', true), b = play('b', true), oneShot = play('one-shot');
end(oneShot);
eq(Howler._howls.length, 3, 'completion releases only its own group');
eq(a.playing(), true); eq(b.playing(), true);
stop('a'); stop('b');
eq(Howler._howls[0], foreign, 'foreign owner is retained');
for (let i = 0; i < 10; i++) {
    const shot = play('repeated'); end(shot);
    eq(Howler._howls.length, 1, 'repeated completed groups do not accumulate');
}
foreign.unload();
eq(Howler._howls.length, 0);
console.log(`kora_sound actual Howler/message lifecycle: ${checks} checks passed`);
