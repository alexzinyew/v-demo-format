module source_demo

import encoding.binary { little_endian_u32 }
import math { f32_from_bits }
import os { File }

pub struct Demo {
mut:
	position int
pub:
	buffer []u8
pub mut:
	header DemoHeader
}

pub struct DemoHeader {
	filestamp      string
	demo_protocol  u32
	net_protocol   u32
	server_name    string
	client_name    string
	map_name       string
	game_dir       string
	time           f32
	ticks          u32
	frames         u32
	sign_on_length u32
}

pub fn (h DemoHeader) str() string {
	return 'Filestamp: ${h.filestamp}
    |Demo protocol: ${h.demo_protocol}
    |Net protocol: ${h.net_protocol}
    |Server name: ${h.server_name}
    |Client name: ${h.client_name}
    |
    |Map name: ${h.map_name}
    |Game dir: ${h.game_dir}
    |Time: ${h.time}
    |Ticks: ${h.ticks}
    |Frames: ${h.frames}
    |Sign on length: ${h.sign_on_length}'.strip_margin()
}

fn (mut d Demo) read_bytes(amount int) ![]u8 {
	if d.position + amount > d.buffer.len {
		return error('Not enough bytes! expected a size of at least ${d.position + amount} bytes, but only has ${d.buffer.len} bytes')
	}

	defer {
		d.position += amount
	}

	return d.buffer[d.position..d.position + amount]
}

fn (mut d Demo) read_string(bytes int) !string {
	return d.read_bytes(bytes)!.bytestr()
}

fn (mut d Demo) read_int() !u32 {
	return little_endian_u32(d.read_bytes(4)!)
}

pub fn (mut d Demo) read_header() ! {
	d.position = 0
	filestamp := d.read_string(8)!#[..-1]

	if filestamp != 'HL2DEMO' {
		return error('Invalid demo file, expected HL2DEMO got: ${filestamp}')
	}

	d.header = DemoHeader{
		filestamp: filestamp
		demo_protocol: d.read_int()!
		net_protocol: d.read_int()!
		server_name: d.read_string(260)!
		client_name: d.read_string(260)!
		map_name: d.read_string(260)!
		game_dir: d.read_string(260)!
		time: f32_from_bits(d.read_int()!)
		ticks: d.read_int()!
		frames: d.read_int()!
		sign_on_length: d.read_int()!
	}
}

pub fn from_bytes(buf []u8) Demo {
	return Demo{
		buffer: buf
	}
}

pub fn from_file(file File) Demo {
	return Demo{
		buffer: file.read_bytes(1076)
	}
}
