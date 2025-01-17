export class Artifacts {
  public ExchangeData: any;
  public ProtocolRegistry: any;
  public LoopringV3: any;
  public ExchangeV3: any;
  public ExchangeProxy: any;
  public BlockVerifier: any;
  public FixPriceDowntimeCostCalculator: any;
  public DummyToken: any;
  public LRCToken: any;
  public GTOToken: any;
  public RDNToken: any;
  public REPToken: any;
  public WETHToken: any;
  public INDAToken: any;
  public INDBToken: any;
  public TESTToken: any;
  public Operator: any;
  public AccountContract: any;
  public LzDecompressor: any;
  public TransferContract: any;
  public PoseidonContract: any;
  public UserStakingPool: any;
  public ProtocolFeeVault: any;

  constructor(artifacts: any) {
    this.ExchangeData = artifacts.require("impl/lib/ExchangeData");
    this.ProtocolRegistry = artifacts.require("impl/ProtocolRegistry");
    this.LoopringV3 = artifacts.require("impl/LoopringV3");
    this.ExchangeV3 = artifacts.require("impl/ExchangeV3");
    this.ExchangeProxy = artifacts.require("impl/ExchangeProxy");
    this.BlockVerifier = artifacts.require("impl/BlockVerifier");
    this.FixPriceDowntimeCostCalculator = artifacts.require(
      "test/FixPriceDowntimeCostCalculator"
    );
    this.DummyToken = artifacts.require("test/DummyToken");
    this.LRCToken = artifacts.require("test/tokens/LRC");
    this.GTOToken = artifacts.require("test/tokens/GTO");
    this.RDNToken = artifacts.require("test/tokens/RDN");
    this.REPToken = artifacts.require("test/tokens/REP");
    this.WETHToken = artifacts.require("test/tokens/WETH");
    this.INDAToken = artifacts.require("test/tokens/INDA");
    this.INDBToken = artifacts.require("test/tokens/INDB");
    this.TESTToken = artifacts.require("test/tokens/TEST");
    this.Operator = artifacts.require("test/Operator");
    this.AccountContract = artifacts.require("test/AccountContract");
    this.LzDecompressor = artifacts.require("test/LzDecompressor");
    this.TransferContract = artifacts.require("test/TransferContract");
    this.PoseidonContract = artifacts.require("test/PoseidonContract");
    this.UserStakingPool = artifacts.require("impl/UserStakingPool");
    this.ProtocolFeeVault = artifacts.require("impl/ProtocolFeeVault");
  }
}
