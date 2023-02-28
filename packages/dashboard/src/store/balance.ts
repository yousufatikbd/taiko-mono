import type { BigNumber } from "ethers";
import { writable } from "svelte/store";

export const balance = writable<BigNumber>();
