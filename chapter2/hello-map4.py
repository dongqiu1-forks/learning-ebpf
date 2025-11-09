#!/usr/bin/python3  
from bcc import BPF
from time import sleep

program = r"""
BPF_HASH(counter_table, u64, u64);

RAW_TRACEPOINT_PROBE(sys_enter) {
   u64 syscall_id;
   u64 counter = 0;
   u64 *p;

   syscall_id = ctx->args[1];  // Get syscall number from tracepoint args
   p = counter_table.lookup(&syscall_id);
   if (p != 0) {
      counter = *p;
   }
   counter++;
   counter_table.update(&syscall_id, &counter);
   return 0;
}
"""

# Syscall name mapping for common syscalls (for display purposes)
SYSCALL_NAMES = {
    0: "read",
    1: "write",
    2: "open", 
    3: "close",
    4: "stat",
    5: "fstat",
    9: "mmap",
    10: "mprotect",
    11: "munmap",
    12: "brk",
    21: "access",
    59: "execve",
    63: "uname",
    89: "readlink",
    102: "getuid",
    104: "getgid",
    107: "geteuid",
    108: "getegid",
    158: "arch_prctl",
    257: "openat",
    262: "newfstatat"
}

b = BPF(text=program)

print("Monitoring all syscall counts across the system...")
print("Press Ctrl+C to stop")

while True:
    sleep(2)
    s = ""
    
    # Get all syscall counts and sort by syscall ID
    syscalls = []
    for k, v in b["counter_table"].items():
        syscalls.append((k.value, v.value))
    
    # Sort by syscall ID for consistent display
    syscalls.sort()
    
    for syscall_id, count in syscalls:
        syscall_name = SYSCALL_NAMES.get(syscall_id, f"syscall_{syscall_id}")
        s += f"{syscall_name}({syscall_id}): {count} "
    
    print(s)
