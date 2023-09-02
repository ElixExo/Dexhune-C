{

    function allocate_unbounded() -> memPtr {
        memPtr := mload(64)
    }

    function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() {
        revert(0, 0)
    }

    function revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() {
        revert(0, 0)
    }

    function revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() {
        revert(0, 0)
    }

    function revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() {
        revert(0, 0)
    }

    function round_up_to_mul_of_32(value) -> result {
        result := and(add(value, 31), not(31))
    }

    function panic_error_0x41() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x41)
        revert(0, 0x24)
    }

    function finalize_allocation(memPtr, size) {
        let newFreePtr := add(memPtr, round_up_to_mul_of_32(size))
        // protect against overflow
        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
        mstore(64, newFreePtr)
    }

    function allocate_memory(size) -> memPtr {
        memPtr := allocate_unbounded()
        finalize_allocation(memPtr, size)
    }

    function array_allocation_size_t_string_memory_ptr(length) -> size {
        // Make sure we can allocate memory without overflow
        if gt(length, 0xffffffffffffffff) { panic_error_0x41() }

        size := round_up_to_mul_of_32(length)

        // add length slot
        size := add(size, 0x20)

    }

    function copy_calldata_to_memory_with_cleanup(src, dst, length) {
        calldatacopy(dst, src, length)
        mstore(add(dst, length), 0)
    }

    function abi_decode_available_length_t_string_memory_ptr(src, length, end) -> array {
        array := allocate_memory(array_allocation_size_t_string_memory_ptr(length))
        mstore(array, length)
        let dst := add(array, 0x20)
        if gt(add(src, length), end) { revert_error_987264b3b1d58a9c7f8255e93e81c77d86d6299019c33110a076957a3e06e2ae() }
        copy_calldata_to_memory_with_cleanup(src, dst, length)
    }

    // string
    function abi_decode_t_string_memory_ptr(offset, end) -> array {
        if iszero(slt(add(offset, 0x1f), end)) { revert_error_1b9f4a0a5773e33b91aa01db23bf8c55fce1411167c872835e7fa00a4f17d46d() }
        let length := calldataload(offset)
        array := abi_decode_available_length_t_string_memory_ptr(add(offset, 0x20), length, end)
    }

    function cleanup_t_uint256(value) -> cleaned {
        cleaned := value
    }

    function validator_revert_t_uint256(value) {
        if iszero(eq(value, cleanup_t_uint256(value))) { revert(0, 0) }
    }

    function abi_decode_t_uint256(offset, end) -> value {
        value := calldataload(offset)
        validator_revert_t_uint256(value)
    }

    function abi_decode_tuple_t_string_memory_ptrt_uint256(headStart, dataEnd) -> value0, value1 {
        if slt(sub(dataEnd, headStart), 64) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := calldataload(add(headStart, 0))
            if gt(offset, 0xffffffffffffffff) { revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db() }

            value0 := abi_decode_t_string_memory_ptr(add(headStart, offset), dataEnd)
        }

        {

            let offset := 32

            value1 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
        }

    }

    function cleanup_t_uint160(value) -> cleaned {
        cleaned := and(value, 0xffffffffffffffffffffffffffffffffffffffff)
    }

    function cleanup_t_address(value) -> cleaned {
        cleaned := cleanup_t_uint160(value)
    }

    function validator_revert_t_address(value) {
        if iszero(eq(value, cleanup_t_address(value))) { revert(0, 0) }
    }

    function abi_decode_t_address(offset, end) -> value {
        value := calldataload(offset)
        validator_revert_t_address(value)
    }

    function abi_decode_tuple_t_address(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := 0

            value0 := abi_decode_t_address(add(headStart, offset), dataEnd)
        }

    }

    function abi_decode_tuple_t_uint256(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := 0

            value0 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
        }

    }

    function abi_encode_t_uint256_to_t_uint256_fromStack(value, pos) {
        mstore(pos, cleanup_t_uint256(value))
    }

    function array_length_t_string_memory_ptr(value) -> length {

        length := mload(value)

    }

    function array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length) -> updated_pos {
        mstore(pos, length)
        updated_pos := add(pos, 0x20)
    }

    function copy_memory_to_memory_with_cleanup(src, dst, length) {
        let i := 0
        for { } lt(i, length) { i := add(i, 32) }
        {
            mstore(add(dst, i), mload(add(src, i)))
        }
        mstore(add(dst, length), 0)
    }

    function abi_encode_t_string_memory_ptr_to_t_string_memory_ptr_fromStack(value, pos) -> end {
        let length := array_length_t_string_memory_ptr(value)
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length)
        copy_memory_to_memory_with_cleanup(add(value, 0x20), pos, length)
        end := add(pos, round_up_to_mul_of_32(length))
    }

    function cleanup_t_bool(value) -> cleaned {
        cleaned := iszero(iszero(value))
    }

    function abi_encode_t_bool_to_t_bool_fromStack(value, pos) {
        mstore(pos, cleanup_t_bool(value))
    }

    function abi_encode_tuple_t_uint256_t_string_memory_ptr_t_uint256_t_uint256_t_uint256_t_uint256_t_bool__to_t_uint256_t_string_memory_ptr_t_uint256_t_uint256_t_uint256_t_uint256_t_bool__fromStack_reversed(headStart , value6, value5, value4, value3, value2, value1, value0) -> tail {
        tail := add(headStart, 224)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        mstore(add(headStart, 32), sub(tail, headStart))
        tail := abi_encode_t_string_memory_ptr_to_t_string_memory_ptr_fromStack(value1,  tail)

        abi_encode_t_uint256_to_t_uint256_fromStack(value2,  add(headStart, 64))

        abi_encode_t_uint256_to_t_uint256_fromStack(value3,  add(headStart, 96))

        abi_encode_t_uint256_to_t_uint256_fromStack(value4,  add(headStart, 128))

        abi_encode_t_uint256_to_t_uint256_fromStack(value5,  add(headStart, 160))

        abi_encode_t_bool_to_t_bool_fromStack(value6,  add(headStart, 192))

    }

    function abi_encode_tuple_t_bool__to_t_bool__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 32)

        abi_encode_t_bool_to_t_bool_fromStack(value0,  add(headStart, 0))

    }

    function validator_revert_t_bool(value) {
        if iszero(eq(value, cleanup_t_bool(value))) { revert(0, 0) }
    }

    function abi_decode_t_bool(offset, end) -> value {
        value := calldataload(offset)
        validator_revert_t_bool(value)
    }

    function abi_decode_tuple_t_bool(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := 0

            value0 := abi_decode_t_bool(add(headStart, offset), dataEnd)
        }

    }

    function abi_encode_t_address_to_t_address_fromStack(value, pos) {
        mstore(pos, cleanup_t_address(value))
    }

    function abi_encode_tuple_t_address__to_t_address__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 32)

        abi_encode_t_address_to_t_address_fromStack(value0,  add(headStart, 0))

    }

    function abi_encode_tuple_t_uint256__to_t_uint256__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 32)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

    }

    function abi_decode_tuple_t_uint256t_bool(headStart, dataEnd) -> value0, value1 {
        if slt(sub(dataEnd, headStart), 64) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := 0

            value0 := abi_decode_t_uint256(add(headStart, offset), dataEnd)
        }

        {

            let offset := 32

            value1 := abi_decode_t_bool(add(headStart, offset), dataEnd)
        }

    }

    function panic_error_0x22() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x22)
        revert(0, 0x24)
    }

    function extract_byte_array_length(data) -> length {
        length := div(data, 2)
        let outOfPlaceEncoding := and(data, 1)
        if iszero(outOfPlaceEncoding) {
            length := and(length, 0x7f)
        }

        if eq(outOfPlaceEncoding, lt(length, 32)) {
            panic_error_0x22()
        }
    }

    function array_dataslot_t_string_storage(ptr) -> data {
        data := ptr

        mstore(0, ptr)
        data := keccak256(0, 0x20)

    }

    function divide_by_32_ceil(value) -> result {
        result := div(add(value, 31), 32)
    }

    function shift_left_dynamic(bits, value) -> newValue {
        newValue :=

        shl(bits, value)

    }

    function update_byte_slice_dynamic32(value, shiftBytes, toInsert) -> result {
        let shiftBits := mul(shiftBytes, 8)
        let mask := shift_left_dynamic(shiftBits, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        toInsert := shift_left_dynamic(shiftBits, toInsert)
        value := and(value, not(mask))
        result := or(value, and(toInsert, mask))
    }

    function identity(value) -> ret {
        ret := value
    }

    function convert_t_uint256_to_t_uint256(value) -> converted {
        converted := cleanup_t_uint256(identity(cleanup_t_uint256(value)))
    }

    function prepare_store_t_uint256(value) -> ret {
        ret := value
    }

    function update_storage_value_t_uint256_to_t_uint256(slot, offset, value_0) {
        let convertedValue_0 := convert_t_uint256_to_t_uint256(value_0)
        sstore(slot, update_byte_slice_dynamic32(sload(slot), offset, prepare_store_t_uint256(convertedValue_0)))
    }

    function zero_value_for_split_t_uint256() -> ret {
        ret := 0
    }

    function storage_set_to_zero_t_uint256(slot, offset) {
        let zero_0 := zero_value_for_split_t_uint256()
        update_storage_value_t_uint256_to_t_uint256(slot, offset, zero_0)
    }

    function clear_storage_range_t_bytes1(start, end) {
        for {} lt(start, end) { start := add(start, 1) }
        {
            storage_set_to_zero_t_uint256(start, 0)
        }
    }

    function clean_up_bytearray_end_slots_t_string_storage(array, len, startIndex) {

        if gt(len, 31) {
            let dataArea := array_dataslot_t_string_storage(array)
            let deleteStart := add(dataArea, divide_by_32_ceil(startIndex))
            // If we are clearing array to be short byte array, we want to clear only data starting from array data area.
            if lt(startIndex, 32) { deleteStart := dataArea }
            clear_storage_range_t_bytes1(deleteStart, add(dataArea, divide_by_32_ceil(len)))
        }

    }

    function shift_right_unsigned_dynamic(bits, value) -> newValue {
        newValue :=

        shr(bits, value)

    }

    function mask_bytes_dynamic(data, bytes) -> result {
        let mask := not(shift_right_unsigned_dynamic(mul(8, bytes), not(0)))
        result := and(data, mask)
    }
    function extract_used_part_and_set_length_of_short_byte_array(data, len) -> used {
        // we want to save only elements that are part of the array after resizing
        // others should be set to zero
        data := mask_bytes_dynamic(data, len)
        used := or(data, mul(2, len))
    }
    function copy_byte_array_to_storage_from_t_string_memory_ptr_to_t_string_storage(slot, src) {

        let newLen := array_length_t_string_memory_ptr(src)
        // Make sure array length is sane
        if gt(newLen, 0xffffffffffffffff) { panic_error_0x41() }

        let oldLen := extract_byte_array_length(sload(slot))

        // potentially truncate data
        clean_up_bytearray_end_slots_t_string_storage(slot, oldLen, newLen)

        let srcOffset := 0

        srcOffset := 0x20

        switch gt(newLen, 31)
        case 1 {
            let loopEnd := and(newLen, not(0x1f))

            let dstPtr := array_dataslot_t_string_storage(slot)
            let i := 0
            for { } lt(i, loopEnd) { i := add(i, 0x20) } {
                sstore(dstPtr, mload(add(src, srcOffset)))
                dstPtr := add(dstPtr, 1)
                srcOffset := add(srcOffset, 32)
            }
            if lt(loopEnd, newLen) {
                let lastValue := mload(add(src, srcOffset))
                sstore(dstPtr, mask_bytes_dynamic(lastValue, and(newLen, 0x1f)))
            }
            sstore(slot, add(mul(newLen, 2), 1))
        }
        default {
            let value := 0
            if newLen {
                value := mload(add(src, srcOffset))
            }
            sstore(slot, extract_used_part_and_set_length_of_short_byte_array(value, newLen))
        }
    }

    function panic_error_0x11() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x11)
        revert(0, 0x24)
    }

    function checked_mul_t_uint256(x, y) -> product {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)
        let product_raw := mul(x, y)
        product := cleanup_t_uint256(product_raw)

        // overflow, if x != 0 and y != product/x
        if iszero(
            or(
                iszero(x),
                eq(y, div(product, x))
            )
        ) { panic_error_0x11() }

    }

    function checked_add_t_uint256(x, y) -> sum {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)
        sum := add(x, y)

        if gt(x, sum) { panic_error_0x11() }

    }

    function abi_encode_tuple_t_uint256_t_string_memory_ptr_t_address__to_t_uint256_t_string_memory_ptr_t_address__fromStack_reversed(headStart , value2, value1, value0) -> tail {
        tail := add(headStart, 96)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        mstore(add(headStart, 32), sub(tail, headStart))
        tail := abi_encode_t_string_memory_ptr_to_t_string_memory_ptr_fromStack(value1,  tail)

        abi_encode_t_address_to_t_address_fromStack(value2,  add(headStart, 64))

    }

    function increment_t_uint256(value) -> ret {
        value := cleanup_t_uint256(value)
        if eq(value, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) { panic_error_0x11() }
        ret := add(value, 1)
    }

    function store_literal_in_memory_816703eb58b6307b3b27d351a49312606d8e715e2707bbade1aaddb79342c4e3(memPtr) {

        mstore(add(memPtr, 0), "An NFT collection cannot have an")

        mstore(add(memPtr, 32), " empty address")

    }

    function abi_encode_t_stringliteral_816703eb58b6307b3b27d351a49312606d8e715e2707bbade1aaddb79342c4e3_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 46)
        store_literal_in_memory_816703eb58b6307b3b27d351a49312606d8e715e2707bbade1aaddb79342c4e3(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_816703eb58b6307b3b27d351a49312606d8e715e2707bbade1aaddb79342c4e3__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_816703eb58b6307b3b27d351a49312606d8e715e2707bbade1aaddb79342c4e3_to_t_string_memory_ptr_fromStack( tail)

    }

    function abi_encode_tuple_t_uint256_t_address__to_t_uint256_t_address__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_address_to_t_address_fromStack(value1,  add(headStart, 32))

    }

    function store_literal_in_memory_bef93e105ab40dd877dbd822b9d58f92f602d8a1a2c2099910d6ae56509b3768(memPtr) {

        mstore(add(memPtr, 0), "The requested proposal does not ")

        mstore(add(memPtr, 32), "exist")

    }

    function abi_encode_t_stringliteral_bef93e105ab40dd877dbd822b9d58f92f602d8a1a2c2099910d6ae56509b3768_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 37)
        store_literal_in_memory_bef93e105ab40dd877dbd822b9d58f92f602d8a1a2c2099910d6ae56509b3768(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_bef93e105ab40dd877dbd822b9d58f92f602d8a1a2c2099910d6ae56509b3768__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_bef93e105ab40dd877dbd822b9d58f92f602d8a1a2c2099910d6ae56509b3768_to_t_string_memory_ptr_fromStack( tail)

    }

    function store_literal_in_memory_f8e344481578112093e0e801a0b49105929f2e2aa55acf8e3d0f6818481e06b8(memPtr) {

        mstore(add(memPtr, 0), "The requested proposal is still ")

        mstore(add(memPtr, 32), "active")

    }

    function abi_encode_t_stringliteral_f8e344481578112093e0e801a0b49105929f2e2aa55acf8e3d0f6818481e06b8_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 38)
        store_literal_in_memory_f8e344481578112093e0e801a0b49105929f2e2aa55acf8e3d0f6818481e06b8(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_f8e344481578112093e0e801a0b49105929f2e2aa55acf8e3d0f6818481e06b8__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_f8e344481578112093e0e801a0b49105929f2e2aa55acf8e3d0f6818481e06b8_to_t_string_memory_ptr_fromStack( tail)

    }

    function abi_encode_tuple_t_uint256_t_bool__to_t_uint256_t_bool__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_bool_to_t_bool_fromStack(value1,  add(headStart, 32))

    }

    function abi_encode_tuple_t_uint256_t_uint256__to_t_uint256_t_uint256__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_uint256_to_t_uint256_fromStack(value1,  add(headStart, 32))

    }

    function store_literal_in_memory_bdf277b96bba45ab4f7ec9d006adfc37cb52d45787409103f95d177d319c7292(memPtr) {

        mstore(add(memPtr, 0), "The requested NFT collection doe")

        mstore(add(memPtr, 32), "s not exist")

    }

    function abi_encode_t_stringliteral_bdf277b96bba45ab4f7ec9d006adfc37cb52d45787409103f95d177d319c7292_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 43)
        store_literal_in_memory_bdf277b96bba45ab4f7ec9d006adfc37cb52d45787409103f95d177d319c7292(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_bdf277b96bba45ab4f7ec9d006adfc37cb52d45787409103f95d177d319c7292__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_bdf277b96bba45ab4f7ec9d006adfc37cb52d45787409103f95d177d319c7292_to_t_string_memory_ptr_fromStack( tail)

    }

    function panic_error_0x32() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x32)
        revert(0, 0x24)
    }

    function checked_sub_t_uint256(x, y) -> diff {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)
        diff := sub(x, y)

        if gt(diff, x) { panic_error_0x11() }

    }

    function panic_error_0x31() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x31)
        revert(0, 0x24)
    }

    function store_literal_in_memory_3d0ed8a636b676a6716ab84644e5065852b27b01de2d332e4c65e66ec9469d95(memPtr) {

        mstore(add(memPtr, 0), "You are not eligible to vote.")

    }

    function abi_encode_t_stringliteral_3d0ed8a636b676a6716ab84644e5065852b27b01de2d332e4c65e66ec9469d95_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 29)
        store_literal_in_memory_3d0ed8a636b676a6716ab84644e5065852b27b01de2d332e4c65e66ec9469d95(pos)
        end := add(pos, 32)
    }

    function abi_encode_tuple_t_stringliteral_3d0ed8a636b676a6716ab84644e5065852b27b01de2d332e4c65e66ec9469d95__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_3d0ed8a636b676a6716ab84644e5065852b27b01de2d332e4c65e66ec9469d95_to_t_string_memory_ptr_fromStack( tail)

    }

    function store_literal_in_memory_13fe987a0c5bad483cf85eb1b7f9c158d755196c79912beb331e43423842595e(memPtr) {

        mstore(add(memPtr, 0), "Voting has been deactivated for ")

        mstore(add(memPtr, 32), "this proposal")

    }

    function abi_encode_t_stringliteral_13fe987a0c5bad483cf85eb1b7f9c158d755196c79912beb331e43423842595e_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 45)
        store_literal_in_memory_13fe987a0c5bad483cf85eb1b7f9c158d755196c79912beb331e43423842595e(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_13fe987a0c5bad483cf85eb1b7f9c158d755196c79912beb331e43423842595e__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_13fe987a0c5bad483cf85eb1b7f9c158d755196c79912beb331e43423842595e_to_t_string_memory_ptr_fromStack( tail)

    }

    function store_literal_in_memory_e548405ba08cdc2f2b1434721199508448dbea7f7571fa43f8174fcad17a2e1c(memPtr) {

        mstore(add(memPtr, 0), "You are not allowed to vote more")

        mstore(add(memPtr, 32), " than once")

    }

    function abi_encode_t_stringliteral_e548405ba08cdc2f2b1434721199508448dbea7f7571fa43f8174fcad17a2e1c_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 42)
        store_literal_in_memory_e548405ba08cdc2f2b1434721199508448dbea7f7571fa43f8174fcad17a2e1c(pos)
        end := add(pos, 64)
    }

    function abi_encode_tuple_t_stringliteral_e548405ba08cdc2f2b1434721199508448dbea7f7571fa43f8174fcad17a2e1c__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_e548405ba08cdc2f2b1434721199508448dbea7f7571fa43f8174fcad17a2e1c_to_t_string_memory_ptr_fromStack( tail)

    }

    function abi_encode_tuple_t_address_t_uint256_t_bool__to_t_address_t_uint256_t_bool__fromStack_reversed(headStart , value2, value1, value0) -> tail {
        tail := add(headStart, 96)

        abi_encode_t_address_to_t_address_fromStack(value0,  add(headStart, 0))

        abi_encode_t_uint256_to_t_uint256_fromStack(value1,  add(headStart, 32))

        abi_encode_t_bool_to_t_bool_fromStack(value2,  add(headStart, 64))

    }

    function abi_encode_tuple_t_address_t_address__to_t_address_t_address__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_address_to_t_address_fromStack(value0,  add(headStart, 0))

        abi_encode_t_address_to_t_address_fromStack(value1,  add(headStart, 32))

    }

    function store_literal_in_memory_c74b02dae53b330f9d5247c6e914bb95735dd9ac40c869ba889a7550aa5762f7(memPtr) {

        mstore(add(memPtr, 0), "This method can only be called b")

        mstore(add(memPtr, 32), "y the owner of this smart contra")

        mstore(add(memPtr, 64), "ct")

    }

    function abi_encode_t_stringliteral_c74b02dae53b330f9d5247c6e914bb95735dd9ac40c869ba889a7550aa5762f7_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 66)
        store_literal_in_memory_c74b02dae53b330f9d5247c6e914bb95735dd9ac40c869ba889a7550aa5762f7(pos)
        end := add(pos, 96)
    }

    function abi_encode_tuple_t_stringliteral_c74b02dae53b330f9d5247c6e914bb95735dd9ac40c869ba889a7550aa5762f7__to_t_string_memory_ptr__fromStack_reversed(headStart ) -> tail {
        tail := add(headStart, 32)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_c74b02dae53b330f9d5247c6e914bb95735dd9ac40c869ba889a7550aa5762f7_to_t_string_memory_ptr_fromStack( tail)

    }

    function abi_decode_t_uint256_fromMemory(offset, end) -> value {
        value := mload(offset)
        validator_revert_t_uint256(value)
    }

    function abi_decode_tuple_t_uint256_fromMemory(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b() }

        {

            let offset := 0

            value0 := abi_decode_t_uint256_fromMemory(add(headStart, offset), dataEnd)
        }

    }

}
