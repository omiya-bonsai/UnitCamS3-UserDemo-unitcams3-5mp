echo "upload asset pool"
parttool.py --port "/dev/cu.usbmodem201301" write_partition --partition-name=assetpool --input "../../build/desktop/AssetPool.bin"
