require 'metasm'

abort 'usage: ruby scan_twbt.rb DwarfFortress.exe 0x121212' if ARGV.length != 2

binpath = ARGV.shift || 'libs/Dwarf_Fortress'
vtoff = Integer(ARGV.shift)

ENV['METASM_NODECODE_RELOCS'] = '1'
dasm = Metasm::AutoExe.decode_file(binpath).disassembler
$dasm = dasm

$ptrsz = 4
$ptrsz = 8 if dasm.cpu.size == 64

# render method
render = dasm.normalize(dasm.decode_dword(vtoff + 2 * $ptrsz))

def find_calls(addr, max_off)
    dasm = $dasm
    dasm.disassemble_fast(addr)

    targets = []

    dasm.each_function_block(addr) { |baddr|
        ldi = dasm.block_at(baddr).list.last

        next if ldi.opcode.name != 'call'
        break if baddr - addr >= max_off

        targets << dasm.resolve(ldi.instruction.args[0])
    }

    return targets
end

render_map = find_calls(render, 50)
if render_map.length != 1
    puts "<!-- CONFLICT global-address name='twbt_render_map' value='#{render_map.map { |a| '0x%08x' % a }.join(' or ')}'/ -->"
else
    puts "<global-address name='twbt_render_map' value='0x#{'%08x' % render_map[0]}'/>"
end

