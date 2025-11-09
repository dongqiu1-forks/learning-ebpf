#!/usr/bin/python3  
from bcc import BPF
from time import sleep

program = r"""
BPF_HASH(counter_table);

int hello(void *ctx) {
   u64 uid;
   u64 counter = 0;
   u64 *p;

   uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
   p = counter_table.lookup(&uid);
   if (p != 0) {
      counter = *p;
   }
   counter++;
   counter_table.update(&uid, &counter);
   return 0;
}

int hello_openat(void *ctx) {
   u64 uid;
   u64 counter = 0;
   u64 *p;

   uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
   p = counter_table.lookup(&uid);
   if (p != 0) {
      counter = *p;
   }
   counter++;
   counter_table.update(&uid, &counter);
   return 0;
}

int hello_write(void *ctx) {
   u64 uid;
   u64 counter = 0;
   u64 *p;

   uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
   p = counter_table.lookup(&uid);
   if (p != 0) {
      counter = *p;
   }
   counter++;
   counter_table.update(&uid, &counter);
   return 0;
}
"""

b = BPF(text=program)

# Attach the same eBPF function to multiple syscalls
execve_syscall = b.get_syscall_fnname("execve")
openat_syscall = b.get_syscall_fnname("openat")
write_syscall = b.get_syscall_fnname("write")

b.attach_kprobe(event=execve_syscall, fn_name="hello")
b.attach_kprobe(event=openat_syscall, fn_name="hello_openat")
b.attach_kprobe(event=write_syscall, fn_name="hello_write")

print(f"Monitoring syscalls: {execve_syscall}, {openat_syscall}, {write_syscall}")

while True:
    sleep(2)
    s = ""
    for k,v in b["counter_table"].items():
        s += f"UID {k.value}: {v.value}\t"
    print(s)
