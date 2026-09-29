import {
  Box,
  Button,
  LabeledList,
  Modal,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CoreInfo = {
  connected_machine: BooleanLike;
  internal_energy: number;
  temp: number;
  min_temperature: number;
  max_temperature: number;
  payload: string;
  bomsize: number;
  fusion_core: string;
};

const CoreDisplay = (props) => {
  const { act, data } = useBackend<CoreInfo>();

  return (
    <Section title={data.fusion_core ?? 'Empty Core Chamber'}>
      <LabeledList>
        <LabeledList.Item label="Temperature">
          <ProgressBar
            value={data.temp ?? 0}
            minValue={data.min_temperature}
            maxValue={data.max_temperature}
            ranges={{
              good: [data.min_temperature, data.max_temperature * 0.5],
              average: [data.max_temperature * 0.7, data.max_temperature],
            }}
          />
        </LabeledList.Item>
        <LabeledList.Item label={data.payload ?? 'No payload detected'}>
          <Button onClick={() => act('begin_implosion')}>
            Begin Implosion
          </Button>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const Unavailable_Core = (props) => {
  return (
    <Modal>
      <Stack fill vertical>
        <Stack.Item textAlign="center">
          <Box style={{ margin: 'auto' }} textAlign="center" width="300px">
            {'No machine detected'}
          </Box>
        </Stack.Item>
      </Stack>
    </Modal>
  );
};

export const CoreMonitor = (props) => {
  const { data } = useBackend<CoreInfo>();

  return (
    <Window width={380} height={240}>
      <Window.Content>
        {data.connected_machine ? <CoreDisplay /> : <Unavailable_Core />}
      </Window.Content>
    </Window>
  );
};
