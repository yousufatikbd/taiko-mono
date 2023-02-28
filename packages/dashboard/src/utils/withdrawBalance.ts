import { ethers, Signer } from "ethers";
import TAIKO_L1 from "../abi/TAIKO_L1";

const withdrawBalance = async (signer: Signer, tokenAddress: string) => {
  const contract = new ethers.Contract(tokenAddress, TAIKO_L1, signer);

  return await contract.withdrawBalance();
};

export default withdrawBalance;
