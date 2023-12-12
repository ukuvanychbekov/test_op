// @ts-ignore
import { utils } from '@xeokit/xeokit-sdk/dist/xeokit-sdk.es';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IFCGonDefinition } from '../pages/viewer/ifc-models-data.service';

/**
 * Default server client which loads content via HTTP from the file system.
 */
export class XeokitServer {
  private ifcModels:IFCGonDefinition;

  /**
   *
   * @param config
   * @param.config.pathHelper instance of PathHelperService.
   */
  constructor(private pathHelper:PathHelperService) {
    this.ifcModels = window.gon.ifc_models;
  }

  /**
   * Gets the manifest of all projects.
   * @param done
   * @param error
   */
  getProjects(done:Function, _error:Function) {
    done({ projects: this.ifcModels.projects });
  }

  /**
   * Gets a manifest for a project.
   * @param projectId
   * @param done
   * @param error
   */
  getProject(projectData:any, done:Function, _error:Function) {
    const manifestData = {
      id: projectData[0].id,
      name: projectData[0].name,
      models: this.ifcModels.models,
      viewerContent: {
        modelsLoaded: this.ifcModels.shown_models,
      },
      viewerConfigs: {},
    };

    done(manifestData);
  }

  /**
   * Gets geometry for a model within a project.
   * @param projectId
   * @param modelId
   * @param done
   * @param error
   */
  getGeometry(projectId:string, modelId:number, done:Function, error:Function) {
    const attachmentId = this.ifcModels.xkt_attachment_ids[modelId];
    console.log(`Loading model geometry for: ${attachmentId}`);
    utils.loadArraybuffer(this.pathHelper.attachmentContentPath(attachmentId), done, error);
  }
}
