/*

  WARNING/NOTE: whenever you want to add an option here you need to
  either

  * mark it as an optional one with `?` suffix,
  * or make sure it works for all the versions in nixpkgs,
  * or check for which kernel versions it will work (using kernel
    changelog, google or whatever) and mark it with `versionOlder` or
    `versionAtLeast`.

  Then do test your change by building all the kernels (or at least
  their configs) in nixpkgs or else you will guarantee lots and lots
  of pain to users trying to switch to an older kernel because of some
  hardware problems with a new one.

*/

{ stdenv, version, extraConfig }:

with stdenv.lib;

''
  # Compress kernel modules for a sizable disk space savings.
  # We chose XZ for size savings
  MODULE_COMPRESS y
  #MODULE_COMPRESS_GZIP y
  MODULE_COMPRESS_XZ y

  # Compress the kernel
  #KERNEL_BZIP2 y
  #KERNEL_GZIP y
  #KERNEL_LZ4 y
  #KERNEL_LZMA y
  #KERNEL_LZO y
  KERNEL_XZ y

  # Enable all of the crypto libraries directly in the kernel
  # This way the kernel supports any of the needed decompression
  # schemes at boot.
  ${optionalString (versionAtLeast version "4.7") ''
    KEY_DH_OPERATIONS y
    SECONDARY_TRUSTED_KEYRING y
  ''}
  ASYMMETRIC_KEY_TYPE y
  SYSTEM_TRUSTED_KEYRING y
  CRYPTO_DEFLATE y
  CRYPTO_LZ4 y
  CRYPTO_LZ4HC y
  CRYPTO_LZO y
  ${optionalString (versionOlder version "4.6") ''
    CRYPTO_ZLIB y
  ''}
  LZ4_COMPRESS y
  LZ4_DECOMPRESS y
  LZ4HC_COMPRESS y
  LZO_COMPRESS y
  LZO_DECOMPRESS y
  XZ_DEC y
  XZ_DEC_X86 y
  ZLIB_INFLATE y
  ZLIB_DEFLATE y
  DECOMPRESS_BZIP2 y
  DECOMPRESS_GZIP y
  DECOMPRESS_LZMA y
  DECOMPRESS_LZO y
  DECOMPRESS_LZ4 y
  DECOMPRESS_XZ y

  # Debugging.
  DEBUG_KERNEL y
  DYNAMIC_DEBUG y
  BACKTRACE_SELF_TEST n
  ${optionalString (versionOlder version "4.11") ''
    DEBUG_NX_TEST n
  ''}
  DEBUG_DEVRES n
  DEBUG_STACK_USAGE n
  DEBUG_STACKOVERFLOW n
  RCU_TORTURE_TEST n
  SCHEDSTATS n
  DETECT_HUNG_TASK y
  ${optionalString (versionAtLeast version "4.10") ''
    # BUG_ON_DATA_CORRUPTION y
  ''}

  # Unix domain sockets.
  UNIX y

  # Power management.
  PM_ADVANCED_DEBUG y
  PM_AUTOSLEEP y
  PM_WAKELOCKS y
  X86_INTEL_LPSS y
  X86_INTEL_PSTATE y
  INTEL_IDLE y
  ${optionalString (versionAtLeast version "4.11") ''
    INTEL_TURBO_MAX_3 y
  ''}
  CPU_FREQ_DEFAULT_GOV_PERFORMANCE y
  ACPI_PCI_SLOT y
  ACPI_HOTPLUG_MEMORY y
  ACPI_BGRT y
  ACPI_APEI y
  CPU_IDLE_GOV_LADDER y

  HOTPLUG_PCI_ACPI y
  HOTPLUG_PCI_CPCI y

  ${optionalString (versionAtLeast version "4.8") ''
    GCC_PLUGINS y
    CPU_FREQ_STAT y
    PCIE_DPC y
    SLAB_FREELIST_RANDOM y
    HARDENED_USERCOPY y
  ''}
  ${optionalString (versionAtLeast version "4.9") ''
    PCIE_PTM y
  ''}

  # Support drivers that need external firmware.
  STANDALONE n

  # Make /proc/config.gz available.
  IKCONFIG y
  IKCONFIG_PROC y

  # Optimize with -O2, not -Os.
  CC_OPTIMIZE_FOR_SIZE n

  # Enable the kernel's built-in memory tester.
  MEMTEST y

  # Include the CFQ I/O scheduler in the kernel, rather than as a
  # module, so that the initrd gets a good I/O scheduler.
  IOSCHED_CFQ y
  BLK_CGROUP y # required by CFQ

  # Enable NUMA.
  NUMA y
  NUMA_BALANCING y

  # Disable some expensive () features.
  PM_TRACE_RTC n

  # Enable various subsystems.
  ACCESSIBILITY y # Accessibility support
  AUXDISPLAY y # Auxiliary Display support
  DONGLE y # Serial dongle support
  HIPPI y
  MTD_COMPLEX_MAPPINGS y # needed for many devices
  SCSI_LOWLEVEL y # enable lots of SCSI devices
  SCSI_LOWLEVEL_PCMCIA y
  SCSI_SAS_ATA y  # added to enable detection of hard drive
  SPI y # needed for many devices
  SPI_MASTER y
  WAN y

  # Networking options.
  IP_PNP n
  IP_MROUTE_MULTIPLE_TABLES y
  IPV6_ROUTER_PREF y
  IPV6_ROUTE_INFO y
  IPV6_OPTIMISTIC_DAD y
  IPV6_SIT_6RD y
  IPV6_SUBTREES y
  IPV6_MULTIPLE_TABLES y
  IPV6_MROUTE_MULTIPLE_TABLES y
  IPV6_MROUTE y
  IPV6_PIMSM_V2 y
  ${optionalString (versionAtLeast version "4.10") ''
    IPV6_SEG6_LWTUNNEL y
    IPV6_SEG6_HMAC y
  ''}
  NETWORK_PHY_TIMESTAMPING y
  NETFILTER_ADVANCED y
  IP_VS_PROTO_TCP y
  IP_VS_PROTO_UDP y
  IP_VS_PROTO_ESP y
  IP_VS_PROTO_AH y
  IP_VS_PROTO_SCTP y
  IP_DCCP_CCID3 n # experimental
  CLS_U32_PERF y
  CLS_U32_MARK y
  ${optionalString (stdenv.system == "x86_64-linux") ''
    BPF_JIT y
  ''}
  NF_CONNTRACK_ZONES y
  NF_CONNTRACK_EVENTS y
  NF_CONNTRACK_TIMEOUT y
  NF_CONNTRACK_TIMESTAMP y
  NETFILTER_NETLINK_GLUE_CT y
  IP_VS_IPV6 y
  IP_DCCP_CCID3 y
  SCTP_DEFAULT_COOKIE_HMAC_SHA1 y
  SCTP_COOKIE_HMAC_SHA1 y
  SCTP_COOKIE_HMAC_MD5 y
  L2TP_V3 y
  NET_CLS_IND y
  ${optionalString (versionAtLeast version "4.6") ''
    BATMAN_ADV_BATMAN_V y
  ''}
  BATMAN_ADV_DAT y
  BATMAN_ADV_NC y
  BATMAN_ADV_MCAST y
  NET_SWITCHDEV y
  NET_L3_MASTER_DEV y
  ${optionalString (versionAtLeast version "4.9") ''
    AF_RXRPC_IPV6 y
  ''}

  MLX5_CORE_EN y
  ${optionalString (versionOlder version "4.8") ''
    MLX4_EN_VXLAN y
    BNX2X_VXLAN y
    ${optionalString (versionAtLeast version "4.6") ''
      BNX2X_GENEVE y
    ''}
    IXGBE_VXLAN y
    I40E_VXLAN y
    ${optionalString (versionAtLeast version "4.6") ''
      I40E_GENEVE y
    ''}
    FM10K_VXLAN y
    ${optionalString (versionAtLeast version "4.7") ''
      QEDE_VXLAN y
      QEDE_GENEVE y
    ''}
    QLCNIC_VXLAN y
  ''}
  VIA_RHINE_MMIO y
  DEFXX_MMIO y

  ISDN y
  NVM y

  # Random Devices
  ${optionalString (versionAtLeast version "4.7") ''
    SYNC_FILE y
    INTEL_PMC_CORE y
  ''}
  ${optionalString (versionAtLeast version "4.10") ''
    INTEL_RDT_A y
  ''}
  SSB_PCMCIAHOST y
  SSB_SDIOHOST y
  SSB_SILENT y
  SSB_DRIVER_GPIO y
  BCMA_HOST_SOC y
  BCMA_DRIVER_GMAC_CMN y
  BCMA_DRIVER_GPIO y
  MEDIA_ANALOG_TV_SUPPORT y
  MEDIA_RADIO_SUPPORT y
  MEDIA_SDR_SUPPORT y
  MEDIA_CONTROLLER y
  VIDEO_AU0828_RC y
  MEDIA_PCI_SUPPORT y
  V4L_PLATFORM_DRIVERS y
  V4L_MEM2MEM_DRIVERS y
  DVB_PLATFORM_DRIVERS y
  RADIO_SI470X y
  ${optionalString (versionAtLeast version "4.6") ''
    DRM_DP_AUX_CHARDEV y
  ''}
  DRM_RADEON_USERPTR y
  DRM_AMDGPU_CIK y
  DRM_AMDGPU_USERPTR y
  ${optionalString (versionAtLeast version "4.5" && versionOlder version "4.9") ''
    DRM_AMD_POWERPLAY y
  ''}
  ${optionalString (versionAtLeast version "4.9") ''
    DRM_AMDGPU_SI y
  ''}
  DRM_VMWGFX_FBCON y
  ${optionalString (versionAtLeast version "4.8") ''
    DRM_I915_GVT y
  ''}
  FIRMWARE_EDID y
  LOGO y
  HID_BATTERY_STRENGTH y
  USB_DYNAMIC_MINORS y
  USB_MUSB_DUAL_ROLE y
  ASYNC_TX_DMA y
  VME_BUS y
  PWM y
  POWERCAP y
  ISCSI_IBFT_FIND y
  ${optionalString (versionAtLeast version "4.11") ''
    LPFC_NVME_INITIATOR y
    LPFC_NVME_TARGET y
  ''}

  CAN_LEDS y
  ${optionalString (versionAtLeast version "4.8") ''
    LEDS_TRIGGER_DISK y
  ''}
  ${optionalString (versionAtLeast version "4.10") ''
    LED_TRIGGER_PHY y
  ''}
  ${optionalString (versionAtLeast version "4.11") ''
    LEDS_BRIGHTNESS_HW_CHANGED y
  ''}

  # Wireless networking.
  CFG80211_WEXT y # Without it, ipw2200 drivers don't build
  IPW2100_MONITOR y # support promiscuous mode
  IPW2200_MONITOR y # support promiscuous mode
  HOSTAP_FIRMWARE y # Support downloading firmware images with Host AP driver
  HOSTAP_FIRMWARE_NVRAM y
  ATH9K_WOW y
  ATH9K_PCI y # Detect Atheros AR9xxx cards on PCI(e) bus
  ATH9K_AHB y # Ditto, AHB bus
  B43_PHY_HT y
  BCMA_HOST_PCI y

  # Enable various FB devices.
  FB y
  FB_EFI y
  FB_NVIDIA_I2C y # Enable DDC Support
  FB_RIVA_I2C y
  FB_ATY_CT y # Mach64 CT/VT/GT/LT (incl. 3D RAGE) support
  FB_ATY_GX y # Mach64 GX support
  FB_SAVAGE_I2C y
  FB_SAVAGE_ACCEL y
  FB_SIS_300 y
  FB_SIS_315 y
  FB_3DFX_ACCEL y
  FB_SIMPLE y
  FB_VESA y
  FRAMEBUFFER_CONSOLE y
  FRAMEBUFFER_CONSOLE_ROTATION y

  # Video configuration.

  # Allow specifying custom EDID on the kernel command line
  DRM_LOAD_EDID_FIRMWARE y

  # Hybrid graphics support
  VGA_SWITCHEROO y

  # Sound.
  SND_DYNAMIC_MINORS y
  SND_AC97_POWER_SAVE y # AC97 Power-Saving Mode
  SND_HDA_INPUT_BEEP y # Support digital beep via input layer
  SND_USB_CAIAQ_INPUT y
  SND_HDA_RECONFIG y
  SND_HDA_PATCH_LOADER y
  SND_HDA_CODEC_CA0132_DSP y
  PSS_MIXER y # Enable PSS mixer (Beethoven ADSP-16 and other compatible)

  # USB serial devices.
  USB_SERIAL_GENERIC y # USB Generic Serial Driver
  USB_SERIAL_KEYSPAN_MPR y # include firmware for various USB serial devices
  USB_SERIAL_KEYSPAN_USA28 y
  USB_SERIAL_KEYSPAN_USA28X y
  USB_SERIAL_KEYSPAN_USA28XA y
  USB_SERIAL_KEYSPAN_USA28XB y
  USB_SERIAL_KEYSPAN_USA19 y
  USB_SERIAL_KEYSPAN_USA18X y
  USB_SERIAL_KEYSPAN_USA19W y
  USB_SERIAL_KEYSPAN_USA19QW y
  USB_SERIAL_KEYSPAN_USA19QI y
  USB_SERIAL_KEYSPAN_USA49W y
  USB_SERIAL_KEYSPAN_USA49WLC y

  # Filesystem options - in particular, enable extended attributes and
  # ACLs for all filesystems that support them.
  FANOTIFY y
  EXT2_FS n
  EXT3_FS n
  EXT4_FS_POSIX_ACL y
  EXT4_FS_SECURITY y
  ${optionalString (versionAtLeast version "4.8") ''
    EXT4_ENCRYPTION y
  ''}
  REISERFS_FS n
  JFS_FS n
  XFS_QUOTA y
  XFS_POSIX_ACL y
  XFS_RT y # XFS Realtime subvolume support
  OCFS2_DEBUG_MASKLOG n
  BTRFS_FS_POSIX_ACL y
  F2FS_FS_SECURITY y
  F2FS_FS_ENCRYPTION y
  FS_DAX y
  FANOTIFY_ACCESS_PERMISSIONS y
  FSCACHE_STATS y
  FSCACHE_HISTOGRAM y
  NTFS_RW y
  HFSPLUS_FS_POSIX_ACL y
  ${optionalString (versionAtLeast version "4.10") ''
    # OVERLAY_FS_REDIRECT_DIR y
  ''}
  UBIFS_FS_ADVANCED_COMPR y
  UBIFS_ATIME_SUPPORT y
  ${optionalString (versionAtLeast version "4.10") ''
    UBIFS_FS_ENCRYPTION y
  ''}
  ${optionalString (versionAtLeast version "4.6") ''
    FAT_DEFAULT_UTF8 y
  ''}
  JFFS2_FS_XATTR y
  JFFS2_COMPRESSION_OPTIONS y
  JFFS2_LZO y
  JFFS2_CMODE_FAVOURLZO y
  ${optionalString (versionAtLeast version "4.8") ''
    EXPORTFS_BLOCK_OPS y
  ''}
  ${optionalString (versionAtLeast version "4.0" && versionOlder version "4.6") ''
    NFSD_PNFS y
  ''}
  NFSD_V2_ACL y
  NFSD_V3 y
  NFSD_V3_ACL y
  NFSD_V4 y
  NFSD_V4_SECURITY_LABEL y
  NFS_FSCACHE y
  NFS_SWAP y
  NFS_V3_ACL y
  NFS_V4_1 y  # NFSv4.1 client support
  NFS_V4_2 y
  NFS_V4_SECURITY_LABEL y
  ${optionalString (versionAtLeast version "4.8") ''
    NFSD_FLEXFILELAYOUT y
  ''}
  CIFS_STATS y
  CIFS_UPCALL y
  CIFS_ACL y
  CIFS_XATTR y
  CIFS_POSIX y
  CIFS_FSCACHE y
  CIFS_DFS_UPCALL y
  CIFS_SMB2 y
  CIFS_SMB311 y
  CEPH_FSCACHE y
  CEPH_FS_POSIX_ACL y
  CEPH_LIB_USE_DNS_RESOLVER y
  ${optionalString (versionAtLeast version "4.8") ''
    PSTORE_LZ4_COMPRESS y
  ''}
  SQUASHFS_FILE_DIRECT y
  SQUASHFS_DECOMP_MULTI_PERCPU y
  SQUASHFS_XATTR y
  SQUASHFS_ZLIB y
  SQUASHFS_LZO y
  SQUASHFS_XZ y
  SQUASHFS_LZ4 y

  # Security related features.
  RANDOMIZE_BASE y
  STRICT_DEVMEM y # Filter access to /dev/mem
  SECURITY_SELINUX_BOOTPARAM_VALUE 0 # Disable SELinux by default
  DEVKMEM n # Disable /dev/kmem
  CC_STACKPROTECTOR_REGULAR y
  USER_NS y # Support for user namespaces

  # AppArmor support
  SECURITY_APPARMOR y
  DEFAULT_SECURITY_APPARMOR y

  # Microcode loading support
  MICROCODE y
  MICROCODE_INTEL y
  MICROCODE_AMD y

  # Misc. options.
  EXPERT y
  STRIP_ASM_SYMS y
  UNUSED_SYMBOLS y
  PERSISTENT_KEYRINGS y
  SECURITY_NETWORK_XFRM y
  DDR y
  FONTS y
  MOUSE_PS2_VMMOUSE y
  GPIO_SYSFS y
  CHARGER_MANAGER y
  POWER_RESET y
  POWER_RESET_RESTART y
  POWER_AVS y
  ${optionalString (versionAtLeast version "4.5") ''
    WATCHDOG_SYSFS y
  ''}
  8139TOO_8129 y
  8139TOO_PIO n # PIO is slower
  AIC79XX_DEBUG_ENABLE n
  AIC7XXX_DEBUG_ENABLE n
  AIC94XX_DEBUG n
  BLK_DEV_INTEGRITY y
  BSD_PROCESS_ACCT_V3 y
  BT_HCIUART_BCSP y
  BT_HCIUART_H4 y # UART (H4) protocol support
  BT_HCIUART_LL y
  BT_RFCOMM_TTY y # RFCOMM TTY support
  BT_BNEP_MC_FILTER y
  BT_BNEP_PROTO_FILTER y
  ${optionalString (versionAtLeast version "4.6") ''
    BT_LEDS y
  ''}
  BT_HCIUART_ATH3K y
  BT_HCIUART_3WIRE y
  BT_HCIUART_INTEL y
  BT_HCIUART_BCM y
  BT_HCIUART_QCA y
  ${optionalString (versionAtLeast version "4.6") ''
    BT_HCIUART_AG6XX y
  ''}
  ${optionalString (versionAtLeast version "4.9") ''
    BT_HCIUART_MRVL y
  ''}
  MAC80211_MESH y
  MAC80211_RC_MINSTREL_VHT y
  RFKILL_INPUT y
  NFC_SHDLC y
  CRASH_DUMP n
  NFTL_RW y
  MTD_NAND_ECC_SMC y
  MTD_NAND_ECC_BCH y
  ${optionalString (versionOlder version "4.8") ''
    ZRAM_LZ4_COMPRESS y
  ''}
  DVB_DYNAMIC_MINORS y # we use udev
  EFI_STUB y
  EFI_MIXED y
  FHANDLE y # used by systemd
  FUSION y # Fusion MPT device support
  IDE n
  IRDA_ULTRA y # Ultra (connectionless) protocol
  JOYSTICK_IFORCE_232 y # I-Force Serial joysticks and wheels
  JOYSTICK_IFORCE_USB y # I-Force USB joysticks and wheels
  JOYSTICK_XPAD_FF y # X-Box gamepad rumble support
  JOYSTICK_XPAD_LEDS y # LED Support for Xbox360 controller 'BigX' LED
  LDM_PARTITION y # Windows Logical Disk Manager (Dynamic Disk) support
  LOGIRUMBLEPAD2_FF y # Logitech Rumblepad 2 force feedback
  LOGO n # not needed
  MEDIA_ATTACH y
  MEGARAID_NEWGEN y
  MODVERSIONS y
  MOUSE_PS2_ELANTECH y # Elantech PS/2 protocol extension
  ${optionalString (versionAtLeast version "4.10") ''
    RMI4_F03 y
    RMI4_F34 y
    RMI4_F55 y
  ''}
  MTRR_SANITIZER y
  ${optionalString (versionAtLeast version "4.8" && versionOlder version "4.9") ''
    SUNXI_CCU y
    SUN8I_H3_CCU y
  ''}
  NET_FC y # Fibre Channel driver support
  ${optionalString (versionAtLeast version "4.8") ''
    NET_NCSI y
  ''}
  PINCTRL_BAYTRAIL y # GPIO on Intel Bay Trail, for some Chromebook internal eMMC disks
  MMC_BLOCK_MINORS 32 # 8 is default. Modern gpt tables on eMMC may go far beyond 8.
  PPP_MULTILINK y # PPP multilink support
  PPP_FILTER y
  REGULATOR y # Voltage and Current Regulator Support
  RC_DEVICES y # Enable IR devices
  RT2800USB_RT55XX y
  ${optionalString (versionAtLeast version "4.9") ''
    RTC_DRV_DS1307_CENTURY y
  ''}
  SCSI_MQ_DEFAULT y
  DM_MQ_DEFAULT y
  DM_UEVENT y
  ${optionalString (versionAtLeast version "4.5") ''
    DM_VERITY_FEC y
  ''}
  SCSI_SCAN_ASYNC y
  SCSI_DH y
  SCSI_LOGGING y # SCSI logging facility
  SERIAL_8250 y # 8250/16550 and compatible serial support
  SLIP_COMPRESSED y # CSLIP compressed headers
  SLIP_SMART y
  HWMON y
  THERMAL_HWMON y # Hardware monitoring support
  UEVENT_HELPER n
  USB_EHCI_ROOT_HUB_TT y # Root Hub Transaction Translators
  USB_EHCI_TT_NEWSCHED y # Improved transaction translator scheduling
  X86_CHECK_BIOS_CORRUPTION y
  X86_MCE y

  # PCI-Expresscard hotplug support
  HOTPLUG_PCI_PCIE y

  # Linux containers.
  NAMESPACES y #  Required by 'unshare' used by 'nixos-install'
  RT_GROUP_SCHED y
  CGROUP_DEVICE y
  ${optionalString (versionAtLeast version "4.10") ''
    CGROUP_BPF y
  ''}
  MEMCG y
  MEMCG_SWAP y
  CGROUP_PIDS y
  ${optionalString (versionAtLeast version "4.11") ''
    CGROUP_RDMA y
  ''}
  ${optionalString (versionOlder version "4.7") ''
    DEVPTS_MULTIPLE_INSTANCES y
  ''}
  BLK_DEV_THROTTLING y
  ${optionalString (versionAtLeast version "4.10") ''
    BLK_DEV_ZONED y
    BLK_WBT y
    BLK_WBT_SQ y
  ''}
  ${optionalString (versionAtLeast version "4.11") ''
    BLK_SED_OPAL y
  ''}
  CFQ_GROUP_IOSCHED y
  CFS_BANDWIDTH y

  # Enable staging drivers.  These are somewhat experimental, but
  # they generally don't hurt.
  STAGING y

  # PROC_EVENTS requires that the netlink connector is not built
  # as a module.  This is required by libcgroup's cgrulesengd.
  CONNECTOR y
  PROC_EVENTS y

  # Tracing.
  FTRACE y
  KPROBES y
  FUNCTION_TRACER y
  FTRACE_SYSCALLS y
  SCHED_AUTOGROUP y
  SCHED_TRACER y
  STACK_TRACER y
  ${optionalString (versionOlder version "4.11") ''
    UPROBES y
    UPROBE_EVENT y
  ''}
  ${optionalString (versionAtLeast version "4.11") ''
    UPROBES y
    UPROBE_EVENTS y
  ''}
  FUNCTION_PROFILER y
  RING_BUFFER_BENCHMARK n

  USERFAULTFD y

  # Devtmpfs support.
  DEVTMPFS y

  X86_AMD_PLATFORM_DEVICE y

  PREEMPT y
  MEMORY y
  MEMORY_HOTPLUG y
  MEMORY_HOTREMOVE y
  MEMORY_FAILURE y
  HZ_300 y
  KEXEC_FILE y
  KEXEC_JUMP y
  IDLE_PAGE_TRACKING y
  ${optionalString (versionAtLeast version "4.9") ''
    GCC_PLUGIN_LATENT_ENTROPY y
  ''}
  ${optionalString (versionAtLeast version "4.11") ''
    GCC_PLUGIN_STRUCTLEAK y
  ''}

  # Easier debugging of NFS issues.
  SUNRPC_DEBUG y

  # Virtualisation.
  PARAVIRT y
  PARAVIRT_SPINLOCKS y
  HYPERVISOR_GUEST y
  ${optionalString (versionOlder version "4.8") ''
    KVM_APIC_ARCHITECTURE y
  ''}
  KVM_ASYNC_PF y
  KVM_COMPAT y
  KVM_DEVICE_ASSIGNMENT y
  KVM_GENERIC_DIRTYLOG_READ_PROTECT y
  KVM_GUEST y
  KVM_MMIO y
  KVM_VFIO y

  XEN y
  XEN_512GB y
  XEN_ACPI y
  XEN_AUTO_XLATE y
  XEN_BACKEND y
  XEN_BALLOON y
  XEN_BALLOON_MEMORY_HOTPLUG y
  XEN_DOM0 y
  XEN_EFI y
  XEN_HAVE_PVMMU y
  XEN_HAVE_VPMU y
  XEN_MCE_LOG y
  XEN_PVH y
  XEN_PVHVM y
  XEN_SAVE_RESTORE y
  XEN_SCRUB_PAGES y
  #XEN_STUB y
  XEN_SYMS y
  XEN_SYS_HYPERVISOR y
  #XEN_TMEM y
  PCI_XEN y
  HVC_XEN y
  HVC_XEN_FRONTEND y
  SWIOTLB_XEN y

  KSM y
  CLEANCACHE y
  FRONTSWAP y

  ${optionalString (stdenv.targetSystem == stdenv.lib.head stdenv.lib.platforms.i686-linux) ''
    HIGHMEM64G y # We need 64 GB (PAE) support for Xen guest support.
  ''}
  VFIO_PCI_VGA y
  VIRTIO_MMIO_CMDLINE_DEVICES y
  ${optionalString (versionAtLeast version "4.11") ''
    VIRTIO_BLK_SCSI y
  ''}
  VIRT_DRIVERS y
  INTEL_IOMMU_SVM y

  # Media support.
  MEDIA_DIGITAL_TV_SUPPORT y
  MEDIA_CAMERA_SUPPORT y
  MEDIA_RC_SUPPORT y
  MEDIA_USB_SUPPORT y
  ${optionalString (versionAtLeast version "4.10") ''
    MEDIA_CEC_SUPPORT y
  ''}

  # Our initrd init uses shebang scripts, so can't be modular.
  BINFMT_SCRIPT y

  # Enable the 9P cache to speed up NixOS VM tests.
  9P_FSCACHE y
  9P_FS_POSIX_ACL y
  9P_FS_SECURITY y

  # Enable transparent support for huge pages.
  TRANSPARENT_HUGEPAGE y
  TRANSPARENT_HUGEPAGE_ALWAYS n
  TRANSPARENT_HUGEPAGE_MADVISE y

  # zram support (e.g for in-memory compressed swap).
  ZSMALLOC y
  ZRAM m
  ZSWAP y

  # Enable PCIe and USB for the brcmfmac driver
  BRCMFMAC_USB y
  BRCMFMAC_PCIE y

  # Support x2APIC (which requires IRQ remapping).
  ${optionalString (stdenv.system == "x86_64-linux") ''
    X86_X2APIC y
    IRQ_REMAP y
  ''}

  # Disable the firmware helper fallback, udev doesn't implement it any more
  FW_LOADER_USER_HELPER_FALLBACK n

  ${extraConfig}
''
