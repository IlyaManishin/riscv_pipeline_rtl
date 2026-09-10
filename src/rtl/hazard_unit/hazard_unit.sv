`include "risc-v.svh"
`include "hazard_unit/hazard_unit_pkg.svh"

module hazard_unit import risc_v_pkg::*, hazard_unit_pkg::*;
(
    input  logic            clk,

    // Struct Inputs
    input  hu_reg_idxs_t    rs_idxs,
    input  hu_regs_wr_t     hu_regs_wr,
    input  hu_wd_t          hu_wd,

    // Control/Branch & Stage Flags
    input  logic            jfexe_M,
    input  logic            dmem_read_E,

    // Top Hazard & Forwarding Outputs
    output hdu_controls_t   hdu_controls,
    output fwd_controls_t   fwd_controls
);

    // =========================================================================
    //  Submodule Instantiations
    // =========================================================================

    rsi_cmp_t rsi_cmp;

    // Register Comparator Instance
    rsi_comparator rsi_comp_inst (
        .rs_idxs ( rs_idxs ),
        .rsi_cmp ( rsi_cmp )
    );

    // Hazard Detection Unit Instance
    (* keep_hierarchy = `HDU_KEEP_HIEARARCHY *)
    hazard_detection_unit hazard_detection_unit_inst (
        .rsi_cmp      ( rsi_cmp      ),
        .hu_regs_wr   ( hu_regs_wr   ),
        .jfexe_M      ( jfexe_M      ),
        .dmem_read_E  ( dmem_read_E  ),
        .hdu_controls ( hdu_controls )
    );

    // Forwarding Unit Instance
    fwd_unit fwd_unit_inst (
        .clk          ( clk          ),
        .rsi_cmp      ( rsi_cmp      ),
        .hu_regs_wr   ( hu_regs_wr   ),
        .hu_wd        ( hu_wd        ),
        .fwd_controls ( fwd_controls )
    );

endmodule : hazard_unit