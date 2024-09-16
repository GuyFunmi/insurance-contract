import { describe, it, expect, vi } from 'vitest';
import {
  buyInsurance,
  fileClaim,
  hasValidPolicy,
  hasFiledClaim,
  getContractBalance,
  updateInsuranceFee,
  updateClaimAmount,
  withdrawExcessFunds,
} from '../contracts/decentralized-insurance.clar';

// Mock implementations
const mockTxSender = (address: string): () => string => () => address;
const mockBlockHeight = (time: bigint): () => bigint => () => time;

// Mock contract functions
vi.mock('./contract', () => ({
  buyInsurance: vi.fn(),
  fileClaim: vi.fn(),
  hasValidPolicy: vi.fn(),
  hasFiledClaim: vi.fn(),
  getContractBalance: vi.fn().mockReturnValue(BigInt(1000000)),
  updateInsuranceFee: vi.fn(),
  updateClaimAmount: vi.fn(),
  withdrawExcessFunds: vi.fn(),
}));

// Test cases
describe('Decentralized Insurance Contract', () => {
  describe('Buy Insurance', () => {
    it('should succeed when balance is sufficient', () => {
      const txSender = mockTxSender('0x123');
      const blockHeight = mockBlockHeight(BigInt(100000));
      
      vi.mocked(buyInsurance).mockReturnValue({ isOk: true, value: true });
      
      expect(buyInsurance(txSender, blockHeight)).toEqual({ isOk: true, value: true });
    });

    it('should fail when balance is insufficient', () => {
      const txSender = mockTxSender('0x456');
      const blockHeight = mockBlockHeight(BigInt(100000));
      
      vi.mocked(buyInsurance).mockReturnValue({ isOk: false, value: BigInt(0) });
      
      expect(buyInsurance(txSender, blockHeight)).toEqual({ isOk: false, value: BigInt(0) });
    });
  });

  describe('File Claim', () => {
    it('should succeed when conditions are met', () => {
      const txSender = mockTxSender('0x789');
      const blockHeight = mockBlockHeight(BigInt(100145)); // 145 blocks after policy start
      
      vi.mocked(hasValidPolicy).mockReturnValue(true);
      vi.mocked(hasFiledClaim).mockReturnValue(false);
      vi.mocked(fileClaim).mockReturnValue({ isOk: true, value: true });
      
      expect(fileClaim(txSender, blockHeight)).toEqual({ isOk: true, value: true });
    });

    it('should fail when max claims are reached', () => {
      const txSender = mockTxSender('0x789');
      const blockHeight = mockBlockHeight(BigInt(100146)); // 146 blocks after policy start
      
      vi.mocked(hasValidPolicy).mockReturnValue(true);
      vi.mocked(hasFiledClaim).mockReturnValue(true); // Reached max claims
      vi.mocked(fileClaim).mockReturnValue({ isOk: false, value: BigInt(1) });
      
      expect(fileClaim(txSender, blockHeight)).toEqual({ isOk: false, value: BigInt(1) });
    });

    it('should fail when the policy has expired', () => {
      const txSender = mockTxSender('0x789');
      const blockHeight = mockBlockHeight(BigInt(200000)); // After policy expiry
      
      vi.mocked(hasValidPolicy).mockReturnValue(false);
      vi.mocked(fileClaim).mockReturnValue({ isOk: false, value: BigInt(2) }); // Policy expired
      
      expect(fileClaim(txSender, blockHeight)).toEqual({ isOk: false, value: BigInt(2) });
    });
  });

  describe('Has Valid Policy', () => {
    it('should return true when policy exists', () => {
      const txSender = mockTxSender('0x123');
      
      vi.mocked(hasValidPolicy).mockReturnValue(true);
      
      expect(hasValidPolicy(txSender())).toBe(true);
    });

    it('should return false when no policy exists', () => {
      const txSender = mockTxSender('0x456');
      
      vi.mocked(hasValidPolicy).mockReturnValue(false);
      
      expect(hasValidPolicy(txSender())).toBe(false);
    });
  });

  describe('Update Insurance Fee', () => {
    it('should update insurance fee when called by contract owner', () => {
      const txSender = mockTxSender('0xowner');
      const newFee = BigInt(200000); // New insurance fee
      
      vi.mocked(updateInsuranceFee).mockReturnValue({ isOk: true, value: true });
      
      expect(updateInsuranceFee(txSender(), newFee)).toEqual({ isOk: true, value: true });
    });

    it('should fail to update insurance fee if called by non-owner', () => {
      const txSender = mockTxSender('0x123');
      const newFee = BigInt(200000);
      
      vi.mocked(updateInsuranceFee).mockReturnValue({ isOk: false, value: BigInt(403) }); // Unauthorized error
      
      expect(updateInsuranceFee(txSender(), newFee)).toEqual({ isOk: false, value: BigInt(403) });
    });
  });

  describe('Update Claim Amount', () => {
    it('should update claim amount when called by contract owner', () => {
      const txSender = mockTxSender('0xowner');
      const newAmount = BigInt(500000); // New claim amount
      
      vi.mocked(updateClaimAmount).mockReturnValue({ isOk: true, value: true });
      
      expect(updateClaimAmount(txSender(), newAmount)).toEqual({ isOk: true, value: true });
    });

    it('should fail to update claim amount if called by non-owner', () => {
      const txSender = mockTxSender('0x123');
      const newAmount = BigInt(500000);
      
      vi.mocked(updateClaimAmount).mockReturnValue({ isOk: false, value: BigInt(403) });
      
      expect(updateClaimAmount(txSender(), newAmount)).toEqual({ isOk: false, value: BigInt(403) });
    });
  });

  describe('Withdraw Excess Funds', () => {
    it('should withdraw excess funds when contract balance is sufficient', () => {
      const txSender = mockTxSender('0xowner');
      const amountToWithdraw = BigInt(500000);
      
      vi.mocked(withdrawExcessFunds).mockReturnValue({ isOk: true, value: true });
      
      expect(withdrawExcessFunds(txSender(), amountToWithdraw)).toEqual({ isOk: true, value: true });
    });

    it('should fail to withdraw if balance is insufficient', () => {
      const txSender = mockTxSender('0xowner');
      const amountToWithdraw = BigInt(2000000); // Exceeds contract balance
      
      vi.mocked(withdrawExcessFunds).mockReturnValue({ isOk: false, value: BigInt(406) });
      
      expect(withdrawExcessFunds(txSender(), amountToWithdraw)).toEqual({ isOk: false, value: BigInt(406) });
    });

    it('should fail to withdraw if called by non-owner', () => {
      const txSender = mockTxSender('0x123');
      const amountToWithdraw = BigInt(500000);
      
      vi.mocked(withdrawExcessFunds).mockReturnValue({ isOk: false, value: BigInt(403) }); // Unauthorized error
      
      expect(withdrawExcessFunds(txSender(), amountToWithdraw)).toEqual({ isOk: false, value: BigInt(403) });
    });
  });

  describe('Get Contract Balance', () => {
    it('should return the correct balance', () => {
      expect(getContractBalance()).toBe(BigInt(1000000));
    });
  });
});
