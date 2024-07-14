const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const _usdt = "0xCdD595184EE2Ece14d16ee60Afe83337Dd04dE67";
const _notary = "0x7cfE552f36359D1c74Bd6b89e448a6d4CcC4eca8";

module.exports = buildModule("EscrowModule", (m) => {
  const usdt = m.getParameter("_usdt", _usdt);
  const notary = m.getParameter("_notary", _notary);

  const escrow = m.contract("USDT_Escrow", [usdt, notary], {});

  return { escrow };
});
