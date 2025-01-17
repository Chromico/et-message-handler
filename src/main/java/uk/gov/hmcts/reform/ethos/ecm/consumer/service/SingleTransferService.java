package uk.gov.hmcts.reform.ethos.ecm.consumer.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import uk.gov.hmcts.ecm.common.client.CcdClient;
import uk.gov.hmcts.ecm.common.helpers.UtilHelper;
import uk.gov.hmcts.ecm.common.model.ccd.CCDRequest;
import uk.gov.hmcts.ecm.common.model.ccd.CaseData;
import uk.gov.hmcts.ecm.common.model.ccd.SubmitEvent;
import uk.gov.hmcts.ecm.common.model.helper.Constants;
import uk.gov.hmcts.ecm.common.model.servicebus.UpdateCaseMsg;
import uk.gov.hmcts.ecm.common.model.servicebus.datamodel.CreationSingleDataModel;
import java.io.IOException;

import static uk.gov.hmcts.ecm.common.model.helper.Constants.SINGLE_CASE_TYPE;

@Slf4j
@RequiredArgsConstructor
@Service
public class SingleTransferService {

    private final CcdClient ccdClient;

    public void sendTransferred(SubmitEvent submitEvent, String accessToken,
                             UpdateCaseMsg updateCaseMsg) throws IOException {

        var creationSingleDataModel =
            ((CreationSingleDataModel) updateCaseMsg.getDataModelParent());
        String positionTypeCT = creationSingleDataModel.getPositionTypeCT();
        String owningOfficeCT = creationSingleDataModel.getOfficeCT();
        String reasonForCT = creationSingleDataModel.getReasonForCT();
        String scopeOfTransfer = creationSingleDataModel.getScopeOfTransfer();

        String jurisdiction = updateCaseMsg.getJurisdiction();

        String caseTypeId = !updateCaseMsg.getMultipleRef().equals(SINGLE_CASE_TYPE)
            ? UtilHelper.getCaseTypeId(updateCaseMsg.getCaseTypeId())
            : updateCaseMsg.getCaseTypeId();

        updateTransferredCase(submitEvent, caseTypeId, owningOfficeCT, jurisdiction, accessToken, positionTypeCT,
                              reasonForCT, scopeOfTransfer);

    }

    private void updateTransferredCase(SubmitEvent submitEvent, String caseTypeId, String owningOfficeCT,
                                       String jurisdiction, String accessToken, String positionTypeCT,
                                       String reasonForCT, String scopeOfTransfer) throws IOException {

        CCDRequest returnedRequest;
        if (Constants.SCOPE_OF_TRANSFER_INTRA_COUNTRY.equals(scopeOfTransfer)) {
            returnedRequest = ccdClient.startEventForCase(accessToken, caseTypeId,
                                                          jurisdiction, String.valueOf(submitEvent.getCaseId()));
        } else {

            returnedRequest = ccdClient.startCaseTransfer(accessToken, caseTypeId, jurisdiction,
                                                                     String.valueOf(submitEvent.getCaseId()));
        }
        generateCaseData(submitEvent.getCaseData(), owningOfficeCT, positionTypeCT, reasonForCT);

        ccdClient.submitEventForCase(accessToken,
                                     submitEvent.getCaseData(),
                                     caseTypeId,
                                     jurisdiction,
                                     returnedRequest,
                                     String.valueOf(submitEvent.getCaseId()));

    }

    private void generateCaseData(CaseData caseData, String owningOfficeCT, String positionTypeCT, String reasonForCT) {

        caseData.setLinkedCaseCT("Transferred to " + owningOfficeCT);
        log.info("Setting positionType to positionTypeCT: " + positionTypeCT
                     + " for case: " + caseData.getEthosCaseReference());
        caseData.setPositionType(positionTypeCT);
        caseData.setPositionTypeCT(positionTypeCT);
        caseData.setReasonForCT(reasonForCT);

    }

}
