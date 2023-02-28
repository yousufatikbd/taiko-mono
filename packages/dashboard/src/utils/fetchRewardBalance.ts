import { ethers, Signer } from "ethers";
import TAIKO_L1 from "src/abi/TAIKO_L1";

const fetchRewardBalance = async (signer: Signer, tokenAddress: string) => {
  const contract = new ethers.Contract(tokenAddress, TAIKO_L1, signer);

  return await contract.getRewardBalance(await signer.getAddress());
};

export default fetchRewardBalance;
