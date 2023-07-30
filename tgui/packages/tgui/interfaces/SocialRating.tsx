import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { useBackend, useLocalState } from 'tgui/backend';
import { Stack, Input, Section, Tabs, NoticeBox, Box, Icon } from 'tgui/components';

export type SocialRatingList = {
  records: SocialRatingData[];
};

export type SocialRatingData = {
  age: number;
  crew_ref: string;
  gender: string;
  name: string;
  rank: string;
  species: string;
};

export const SocialRatingTabs = (props, context) => {
  const { act, data } = useBackend<SocialRatingList>(context);
  const { records = [] } = data;

  const errorMessage = !records.length
    ? 'No records found.'
    : 'No match. Refine your search.';

  const [search, setSearch] = useLocalState(context, 'search', '');

  const sorted: SocialRatingData[] = flow([
    filter((record: SocialRatingData) => isRecordMatch(record, search)),
    sortBy((record: SocialRatingData) => record.name?.toLowerCase()),
  ])(records);

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Input
          fluid
          onInput={(_, value) => setSearch(value)}
          placeholder="Name/Job/DNA"
        />
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <Tabs vertical>
            {!sorted.length ? (
              <NoticeBox>{errorMessage}</NoticeBox>
            ) : (
              sorted.map((record, index) => (
                <CrewTab key={index} record={record} />
              ))
            )}
          </Tabs>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

/** Individual crew tab */
const CrewTab = (props: { record: SocialRatingData }, context) => {
  const [selectedRecord, setSelectedRecord] = useLocalState<
    SocialRatingData | undefined
  >(context, 'medicalRecord', undefined);

  const { act, data } = useBackend<SocialRatingList>(context);
  const { record } = props;
  const { crew_ref, name, rank } = record;

  /** Sets the record to preview */
  const selectRecord = (record: SocialRatingData) => {
    if (selectedRecord?.crew_ref === crew_ref) {
      setSelectedRecord(undefined);
    } else {
      setSelectedRecord(record);
    }
  };

  return (
    <Tabs.Tab
      className="candystripe"
      label={name}
      onClick={() => selectRecord(record)}
      selected={selectedRecord?.crew_ref === crew_ref}>
      <Box wrap>
        <Icon name={JOB2ICON[rank] || 'question'} /> {name}
      </Box>
    </Tabs.Tab>
  );
};
