import ballerina/ftp;
import ballerina/http;
import ballerina/io;

configurable string serviceUrl = ?;
configurable string coreAdminApikey = ?;

public function main() returns error? {

    http:Client httpEp = check new (url = serviceUrl, config = {
        timeout: 10
    });
    map<string> headers = {
        "Accept": "application/vnd.mambu.v2+json",
        "apiKey": coreAdminApikey,
        "Content-Type": "application/json"
    };

    LoanAccount loanAccount = check httpEp->/loans/MPZE230(headers);
    //io:println(loanAccount.loanName);

    LoanAccountExport[] lae = [];
    lae[0] = transform(loanAccount);

    check io:fileWriteCsv("/Users/rmani/test.json", lae);

    // This is the problem, where it is failing with error.
    // basically sftp -i /Users/rmani/.ssh/onmo-integration  mani.ram@sftp.staging.onmo.app works, but I couldn't get following to connect.
    ftp:Client ftpEp = check new (clientConfig = {
        protocol: ftp:SFTP,
        host: "sftp.staging.onmo.app",
        port: 22,
        auth: {
            credentials: {
                username: "mani.ram",
                password: ""
            },
            privateKey: {
                path: "/Users/rmani/.ssh/onmo-integration"
            }
        }
    });

    ftp:FileInfo[] files = check ftpEp->list("/onmo-integration-file/inbound/");
    io:println(files[0].name);

    stream<io:Block, io:Error?> fileStream
        = check io:fileReadBlocksAsStream("/Users/rmani/test.json", 1024);
    check ftpEp->put("/onmo-integration-file/inbound/logFile.txt", fileStream);
    check fileStream.close();

    return ();
}

type LoanAccountExport record {
    string encodedKey;
    string id;
    string accountHolderType;
    string accountHolderKey;
    string creationDate;
    string approvedDate;
    string lastModifiedDate;
    string activationTransactionKey;
    string lastSetToArrearsDate;
    string lastAccountAppraisalDate;

    decimal principalDue;
    decimal principalPaid;
    decimal principalBalance;
};

type LoanAccount record {
    string encodedKey;
    string id;
    string accountHolderType;
    string accountHolderKey;
    string creationDate;
    string approvedDate;
    string lastModifiedDate;
    string activationTransactionKey;
    string lastSetToArrearsDate;
    string lastAccountAppraisalDate;
    string accountState;
    string productTypeKey;
    string creditArrangementKey;
    string loanName;
    decimal loanAmount;
    string paymentMethod;
    string assignedBranchKey;
    decimal accruedInterest;
    int interestFromArrearsAccrued;
    //    string lastInterestAppliedDate;
    //    int accruedPenalty;
    //    boolean allowOffset;
    int arrearsTolerancePeriod;
    record {
        string encodedKey;
        string toleranceCalculationMethod;
        string dateCalculationMethod;
        string nonWorkingDaysMethod;
        int tolerancePeriod;
        int tolerancePercentageOfOutstandingPrincipal;
    } accountArrearsSettings;
    string latePaymentsRecalculationMethod;
    record {
        int redrawBalance;
        decimal principalDue;
        decimal principalPaid;
        decimal principalBalance;
        decimal interestDue;
        int interestPaid;
        decimal interestBalance;
        int interestFromArrearsBalance;
        int interestFromArrearsDue;
        int interestFromArrearsPaid;
        int feesDue;
        int feesPaid;
        int feesBalance;
        int penaltyDue;
        int penaltyPaid;
        int penaltyBalance;
        int holdBalance;
    } balances;
    record {
        string encodedKey;
        string principalPaymentMethod;
        decimal principalFloorValue;
        boolean includeInterestInFloorAmount;
        boolean includeFeesInFloorAmount;
        decimal percentage;
    } principalPaymentSettings;
    record {
        string encodedKey;
        string disbursementDate;
        anydata[] fees;
    } disbursementDetails;
    record {
        string prepaymentRecalculationMethod;
        string principalPaidInstallmentStatus;
        string applyInterestOnPrepaymentMethod;
    } prepaymentSettings;
    record {
        string loanPenaltyCalculationMethod;
        int penaltyRate;
    } penaltySettings;
    record {
        boolean hasCustomSchedule;
        int principalRepaymentInterval;
        int gracePeriod;
        string gracePeriodType;
        int repaymentInstallments;
        string shortMonthHandlingMethod;
        int[] fixedDaysOfMonth;
        int repaymentPeriodCount;
        string scheduleDueDatesMethod;
        int periodicPayment;
        string repaymentPeriodUnit;
        string repaymentScheduleMethod;
        anydata[] paymentPlan;
        record {
            int[] days;
        } billingCycle;
        record {
            int numberOfPreviewedInstalments;
        } previewSchedule;
    } scheduleSettings;
    record {
        string interestRateSource;
        boolean accrueInterestAfterMaturity;
        string interestApplicationMethod;
        string interestBalanceCalculationMethod;
        string interestCalculationMethod;
        string interestChargeFrequency;
        decimal interestRate;
        string interestType;
        boolean accrueLateInterest;
    } interestSettings;
    string futurePaymentsAcceptance;
    string originalAccountKey;
    record {
        string currencyCode;
        string code;
    } currency;
};

function transform(LoanAccount loanAccount) returns LoanAccountExport => {
    encodedKey: loanAccount.encodedKey,
    id: loanAccount.id,
    accountHolderType: loanAccount.accountHolderType,
    accountHolderKey: loanAccount.accountHolderKey,
    creationDate: loanAccount.creationDate,
    approvedDate: loanAccount.approvedDate,
    lastModifiedDate: loanAccount.lastModifiedDate,
    activationTransactionKey: loanAccount.activationTransactionKey,
    lastSetToArrearsDate: loanAccount.lastSetToArrearsDate,
    lastAccountAppraisalDate: loanAccount.lastAccountAppraisalDate,
    principalDue: loanAccount.balances.principalDue,
    principalPaid: loanAccount.balances.principalPaid,
    principalBalance: loanAccount.balances.principalBalance
};

