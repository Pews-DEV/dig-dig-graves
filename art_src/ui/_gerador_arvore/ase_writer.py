"""Grava .aseprite indexado (Lua de Cova 32) sem precisar do Aseprite.

Formato: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
Uma camada ("arte"), N frames, cels comprimidas (zlib), paleta de 33 entradas
(indice 0 = transparente, 1..32 = cores 01..32).
"""
import struct
import zlib
from common import PAL


def _chunk(ctype, data):
    return struct.pack('<IH', len(data) + 6, ctype) + data


def _palette_chunk():
    n = 33
    body = struct.pack('<III', n, 0, n - 1) + b'\0' * 8
    body += struct.pack('<HBBBB', 0, 0, 0, 0, 0)
    for r, g, b in PAL:
        body += struct.pack('<HBBBB', 0, r, g, b, 255)
    return _chunk(0x2019, body)


def _old_palette_chunk():
    body = struct.pack('<HBB', 1, 0, 33)
    body += bytes((0, 0, 0))
    for r, g, b in PAL:
        body += bytes((r, g, b))
    return _chunk(0x0004, body)


def _layer_chunk(name):
    nb = name.encode('utf-8')
    body = struct.pack('<HHHHHHB3s', 3, 0, 0, 0, 0, 0, 255, b'\0' * 3)
    body += struct.pack('<H', len(nb)) + nb
    return _chunk(0x2004, body)


def _cel_chunk(canvas):
    raw = bytes(v for row in canvas.px for v in row)
    body = struct.pack('<HhhBHh5s', 0, 0, 0, 255, 2, 0, b'\0' * 5)
    body += struct.pack('<HH', canvas.w, canvas.h) + zlib.compress(raw, 9)
    return _chunk(0x2005, body)


def _tags_chunk(tags):
    body = struct.pack('<H8s', len(tags), b'\0' * 8)
    for name, a, b, direction in tags:
        d = {'forward': 0, 'reverse': 1, 'pingpong': 2}[direction]
        nb = name.encode('utf-8')
        body += struct.pack('<HHBH6s3sB', a, b, d, 0, b'\0' * 6, b'\0' * 3, 0)
        body += struct.pack('<H', len(nb)) + nb
    return _chunk(0x2018, body)


def write_ase(path, frames, durations=None, tags=()):
    """frames: lista de Canvas (mesmo tamanho). durations em ms."""
    w, h = frames[0].w, frames[0].h
    durations = durations or [100] * len(frames)
    out = b''
    for i, f in enumerate(frames):
        chunks = []
        if i == 0:
            chunks += [_old_palette_chunk(), _palette_chunk(), _layer_chunk('arte')]
            if tags:
                chunks.append(_tags_chunk(tags))
        chunks.append(_cel_chunk(f))
        data = b''.join(chunks)
        out += struct.pack('<IHHH2sI', len(data) + 16, 0xF1FA, min(len(chunks), 0xFFFF),
                           durations[i], b'\0' * 2, len(chunks)) + data
    header = struct.pack('<IHHHHHIHII', 128 + len(out), 0xA5E0, len(frames), w, h, 8, 1, 100, 0, 0)
    header += struct.pack('<B3sHBBhhHH', 0, b'\0' * 3, 33, 1, 1, 0, 0, 16, 16)
    header += b'\0' * (128 - len(header))
    assert len(header) == 128
    with open(path, 'wb') as fh:
        fh.write(header + out)


def read_ase(path):
    """Leitor minimo para conferir o que foi gravado: devolve (w, h, [linhas de indices por frame])."""
    data = open(path, 'rb').read()
    size, magic, nframes, w, h, depth = struct.unpack_from('<IHHHHH', data, 0)
    assert magic == 0xA5E0 and depth == 8 and size == len(data)
    pos = 128
    frames = []
    for _ in range(nframes):
        fsize, fmagic, _old, _dur, _pad, nchunks = struct.unpack_from('<IHHH2sI', data, pos)
        assert fmagic == 0xF1FA
        p = pos + 16
        for _ in range(nchunks):
            csize, ctype = struct.unpack_from('<IH', data, p)
            if ctype == 0x2005:
                cw, ch = struct.unpack_from('<HH', data, p + 6 + 16)
                raw = zlib.decompress(data[p + 6 + 20:p + csize])
                frames.append([list(raw[y * cw:(y + 1) * cw]) for y in range(ch)])
            p += csize
        pos += fsize
    return w, h, frames
